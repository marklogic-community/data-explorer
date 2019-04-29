xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
declare option xdmp:mapping "false";


declare variable $sampleSize := 384; (: 95% +/-5% confidence :)
declare variable $sampleThreshold := 1000;


declare function local:sampleFs() {
  local:sampleFs( xdmp:database-name(xdmp:database()) )
};

declare function local:sampleFs($databaseName) {

  let $out := xdmp:eval('
    declare variable $sampleSize as xs:int external;
    declare variable $sampleThreshold as xs:int external;


    declare function local:HSVtoRGB($h, $s, $v) {
        let $i := math:floor($h * 6)
        let $f := $h * 6 - $i
        let $p := $v * (1 - $s)
        let $q := $v * (1 - $f * $s)
        let $t := $v * (1 - (1 - $f) * $s)
        return 
          switch ($i mod 6)
            case 0 return ( round($v * 255), round($t * 255), round($p * 255) )
            case 1 return ( round($q * 255), round($v * 255), round($p * 255) )
            case 2 return ( round($p * 255), round($v * 255), round($t * 255) )
            case 3 return ( round($p * 255), round($q * 255), round($v * 255) )
            case 4 return ( round($t * 255), round($p * 255), round($v * 255) )
            case 5 return ( round($v * 255), round($p * 255), round($q * 255) )
            default return (255,255,255)

    };

    declare function local:codeToHex($rgbColors) {
      let $hex := ("0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F")
      let $values := (
        math:floor($rgbColors[1] div 16) + 1, $rgbColors[1] - math:floor($rgbColors[1] div 16)*16 + 1,
        math:floor($rgbColors[2] div 16) + 1, $rgbColors[2] - math:floor($rgbColors[2] div 16)*16 + 1,
        math:floor($rgbColors[3] div 16) + 1, $rgbColors[3] - math:floor($rgbColors[3] div 16)*16 + 1
      )
      return ("#"
        || $hex[$values[1]] || $hex[$values[2]] || $hex[$values[3]]
        || $hex[$values[4]] || $hex[$values[5]] || $hex[$values[6]]
      )
    };

    declare function local:hexToInt($hex) {
      let $hex := fn:upper-case($hex)
      return fn:sum(
        for $i in (1 to fn:string-length($hex))
        let $letter := fn:substring($hex, $i, 1)
        return xs:int((math:pow(16, $i - 1)) * (switch($letter)
          case "A" return xs:int(10)
          case "B" return xs:int(11)
          case "C" return xs:int(12)
          case "D" return xs:int(13)
          case "E" return xs:int(14)
          case "F" return xs:int(15)
          default return xs:int($letter)
      )))
    };

    declare function local:colorHash($string) {
      let $hash := xdmp:md5($string)
      let $len := math:floor(fn:string-length($hash) div 3)
      (: Divide hash into 3 parts, representing Hue, Saturation, and Value :)
      (: Only generate values with higher Saturations and Values, because they prettier :)
      let $hsv := (
        local:hexToInt( fn:substring($hash, ($len * 0) + 1, $len) ) mod 256,
        156 + local:hexToInt( fn:substring($hash, ($len * 1) + 1, $len) ) mod 100,
        156 + local:hexToInt( fn:substring($hash, ($len * 2) + 1, $len) ) mod 100
      )
      let $rgb := local:HSVtoRGB($hsv[1] div 256,$hsv[2] div 256,$hsv[3] div 256)
      let $rgbhex := local:codeToHex($rgb)
      return $rgbhex
    };

    declare function local:getDocTypes($knownDocTypes) {
      let $negations := 
        for $k in $knownDocTypes
        return if ($k instance of xs:QName) then (
          cts:not-query(cts:element-query($k, cts:and-query(()) ))
        ) else ()
      let $numDocs := xdmp:estimate(cts:search(/, cts:and-query(( $negations ))))
      let $docTypes := 
        fn:distinct-values(
          let $dataset := 
            if ($numDocs gt $sampleThreshold) 
            then cts:search(/, cts:and-query(( $negations )), "score-random" )[1 to $sampleSize]
            else cts:search(/, cts:and-query(( $negations )))

          for $d in $dataset
            let $contentType := xdmp:uri-content-type($d/fn:base-uri())
            let $extension := fn:tokenize(fn:tokenize($d/fn:base-uri(), "\.")[fn:last()], "/")[fn:last()]
            return 
              if (fn:matches($contentType,"/xml"))
              then fn:node-name($d/element())
              else if (fn:matches($contentType, "/x-unknown-content-type"))
              then $contentType
              else fn:string-join(($contentType,$extension), "|")
        )
      return $docTypes
    };


    let $docTypes := ()
    let $_ :=
      for $i in (1 to 3)
      return xdmp:set( $docTypes, ($docTypes, local:getDocTypes($docTypes)) )
    let $docTypes := fn:distinct-values( $docTypes )


    let $out :=
      "[" || fn:string-join((
        for $p at $i in 
          (: Order by frequency:)
          for $d in $docTypes
          let $extension := if ($d instance of xs:QName) then () else fn:tokenize($d, "\|")[fn:last()]
          let $d := if ($d instance of xs:QName) then $d else fn:tokenize($d, "\|")[1]
          let $isContentType := if (fn:matches(fn:string($d), "/")) then fn:true() else fn:false()
          let $numdocs := 
            if ($isContentType) then fn:count(cts:uri-match("*." || $extension))
            else xdmp:estimate(cts:search(/, cts:and-query(( cts:element-query($d, cts:and-query(()) ) )) ))
          where $numdocs gt 0
          order by $numdocs descending, $d ascending
          return $d||","||$numdocs
        let $pieces := fn:tokenize($p, ",")
        let $d := $pieces[1]
        let $numdocs := $pieces[2]
        return "{ ""name"": """ || $d 
          || """, ""value"": " || $numdocs 
          || ", ""color"": """ || local:colorHash($d) || """ }" 
      ), ",") || "]"

    (: JSON return :)
    let $_ :=
      if ($out eq "[]") then (
        xdmp:set($out, "[{
            ""id"": ""X"",
            ""name"": ""Empty"",
            ""color"": ""#DFDFDF"",
            ""value"": 1
          }]"
        )
      ) else ()


    return $out
    
    
    ', (
      xs:QName("sampleSize"), $sampleSize,
      xs:QName("sampleThreshold"), $sampleThreshold
    ), 
    
    <options xmlns="xdmp:eval">
      <database>{xdmp:database($databaseName)}</database>
    </options>
  )

  return document { $out }
};





if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (
  let $database := map:get($cfg:getRequestFieldsMap, "dbName")
  let $database := if ( fn:empty($database) ) then () else xdmp:url-decode($database)
  return
    if ($database and fn:string-length($database) gt 0 and $database ne "undefined") then (
      local:sampleFs($database)
    ) else (
      local:sampleFs()
    )
)
else (xdmp:set-response-code(401, "User is not authorized."))


