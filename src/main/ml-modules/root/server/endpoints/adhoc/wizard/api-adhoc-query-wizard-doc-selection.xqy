xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const"
at "/server/lib/const.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace detail-lib = "http://www.marklogic.com/data-explore/lib/detail-lib" at "/server/lib/detail-lib.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";

declare function local:get-uris-by-directory($path, $max-uris,$start-uri,$db) {
let $max-uris:=xs:int($max-uris)
let $max-uris-plus1:=$max-uris+1
let $path:=if(fn:ends-with($path,"/")) then $path else $path||"/"
let $path:=if(fn:starts-with($path,"/")) then $path else "/"||$path

let $query:=<query>
cts:uris("{$start-uri}",('score-zero',"limit={$max-uris-plus1}"),cts:directory-query("{$path}","infinity"))[2 to {$max-uris-plus1}]
</query>/text()
    return xu:eval($query,(),
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};
declare function local:get-uris-by-partial-uri($path, $max-uris,$start-uri,$db) {
let $start-uri:=if($start-uri castable as xs:int) then xs:int($start-uri) else 1
let $end-uri:=$start-uri + xs:int($max-uris)

let $query:=<query>
cts:uri-match("{$path}",('score-zero'))[{$start-uri} to {$end-uri}]
</query>/text()
    return xu:eval($query,(),
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};
declare function local:get-uris-by-collection-name($collection-name, $max-uris,$start-uri,$db) {
   let $max-uris:=xs:int($max-uris)
   let $max-uris-plus1:=$max-uris+1
   let $query:=<query>cts:uris("{$start-uri}",('score-zero',"limit={$max-uris-plus1}"),
                     cts:collection-query("{$collection-name}"))
                     [2 to {$max-uris-plus1}]
                  </query>/text()
    
    return xu:eval($query,(),
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};
declare function local:get-uris-by-root-element-name($element-name, $max-uris,$start-uri,$db) {
    let $max-uris:=xs:int($max-uris)
    let $max-uris-plus1:=$max-uris+1
    let $query:=let $root-name:=tokenize($element-name,"~")[1]
                let $ns:=tokenize($element-name,"~")[2]
                return 
                  <query>
                     cts:uris("{$start-uri}",('score-zero',"limit={$max-uris-plus1}"),cts:element-query(fn:QName("{$ns}","{$root-name}"),cts:true-query()))
                     [2 to {$max-uris-plus1}]
                  </query>/text()
    
    return xu:eval($query,(),
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};
declare function local:get-root-element-names($db) {
    let $query:=<query>
                    declare variable $sampleSize := 384; (: 95% +/-5% confidence :)
                    declare variable $sampleThreshold := 1000;
                    let $numDocs := xdmp:estimate(cts:search(/, cts:true-query()))
                  return fn:distinct-values(
                      if ($numDocs gt $sampleThreshold) then
                        (: Just get a sample :)
                        for $d in cts:search(/, cts:and-query(()), "score-random" )[1 to $sampleSize]
                           return if($d/element()) then
                            let $qname:=fn:node-name($d/element())
                            return $qname||"~"||fn:namespace-uri-from-QName($qname) else ()
                      else
                        for $d in cts:search(/, cts:and-query(()))                        
                          return if($d/element()) then
                          let $qname:=fn:node-name($d/element())
                          return $qname||"~"||fn:namespace-uri-from-QName($qname) else ()
                    )
                </query>/text()
  
    return xu:eval($query,(),
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
    )
};
declare function local:get-doc-by-uri($doc-uri, $db) {
    xu:eval(
    "fn:doc('"||$doc-uri||"')[1]",
    (),
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};
try {
  if (check-user-lib:is-logged-in() and check-user-lib:is-wizard-user())
  then
    let $_:= ll:trace("api-adhoc-query-wizard-doc-selection:User is logged in")
    
    let $db := xdmp:get-request-field("database")
    let $doc-uri := xdmp:get-request-field("docUri")
    let $collection-name := xdmp:get-request-field("collectionName")
    let $directory := xdmp:get-request-field("directory")
    let $root-element := xdmp:get-request-field("rootElementName")
    let $start-uri := xdmp:get-request-field("startUri")
    let $partialUri := xdmp:get-request-field("partialUri")
    
    let $max-uris := "10"
    let $_:=ll:trace("api-adhoc-query-wizard-doc-selection:database-name = "||$db)
    let $_:=ll:trace("api-adhoc-query-wizard-doc-selection:doc-uri = "||$doc-uri)
    let $_:=ll:trace("api-adhoc-query-wizard-doc-selection:collection-name = "||$collection-name)
    let $_:=ll:trace("api-adhoc-query-wizard-doc-selection:directory = "||$directory)
    let $_:=ll:trace("api-adhoc-query-wizard-doc-selection:root-element ="||$root-element)
    let $_:=ll:trace("api-adhoc-query-wizard-doc-selection:start-uri ="||$start-uri)
    
    return if($doc-uri) then 
        let $content-type := detail-lib:get-document-content-type($doc-uri,$db)
        let $doc := if ( $content-type = "application/xml") then
                        detail-lib:get-document($doc-uri,$db)/element()
                    else
                        detail-lib:get-document($doc-uri,$db)    
       return (xdmp:set-response-content-type($content-type),$doc)
    else
        let $search-results:=if($directory) then 
                                    local:get-uris-by-directory($directory, $max-uris,$start-uri,$db)
                             else if($collection-name) then local:get-uris-by-collection-name($collection-name, $max-uris,$start-uri,$db)
                             else if($root-element) then local:get-uris-by-root-element-name($root-element, $max-uris,$start-uri,$db)
                             else if($partialUri) then 
                                    local:get-uris-by-partial-uri($partialUri, $max-uris,$start-uri,$db)
                             else local:get-root-element-names($db)
        let $json-results:=to-json:string-sequence-to-json($search-results)
        return "{"||<json>"results":[{$json-results}]</json>/text()||"}"
  else
    xdmp:set-response-code(401, "User is not authorized.")
    
} catch ($e) {
  ll:trace(
    ("api-adhoc-query-wizard-doc-selection::Error selecting sample doc", xdmp:quote($e))),
  xdmp:rethrow()
}