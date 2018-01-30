xquery version "1.0-ml";

import module namespace search-lib = "http://marklogic.com/data-explore/lib/search-lib"
  at "/server/lib/search-lib.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;


declare function local:xdmpEval($xquery as xs:string, $vars as item()*, $db as xs:string)
{
  xu:eval(
    $xquery,
    $vars,
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};

declare function local:xdmpInvoke($module as xs:string, $params as item()*, $db as xs:string)
{
   xu:invoke(
    "/controller/search-lib.xqy",
    $params,
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};

declare function local:get-code-from-form-query(
  $doc-type as xs:string,
  $query-name as xs:string)
  as xs:string
{
  let $code := cfg:get-form-query($doc-type, $query-name)/fn:string(code)
  let $log := if ($cfg:D) then xdmp:log(text{ "get-code-from-form-query, $code = ", $code }) else ()
  return
    (: prevent XQuery injection attacks :)
    if (fn:contains($code, ";")) then
      fn:error((), "Form processing XQuery may not contain a semicolon")
    else if (fn:contains($code, "xdmp:eval")) then
      fn:error((), "Form processing XQuery may not contain xdmp:eval")
    else if (fn:contains($code, "xdmp:invoke")) then
      fn:error((), "Form processing XQuery may not contain xdmp:invoke")
    else
      $code
};

declare function local:get-result()
{
  let $doc-type := map:get($cfg:getRequestFieldsMap, "docType")
  let $database := map:get($cfg:getRequestFieldsMap, "database")
  let $query-name := map:get($cfg:getRequestFieldsMap, "queryName")
  let $view-name := map:get($cfg:getRequestFieldsMap, "viewName")
  let $pagination-size := map:get($cfg:getRequestFieldsMap, "pagination-size")
  let $export-csv := map:get($cfg:getRequestFieldsMap, "exportCsv")
  
  (: transaction-mode "query" causes XDMP-UPDATEFUNCTIONFROMQUERY on any update :)
  let $code-with-prolog :=
    $cfg:PROLOG||  local:get-code-from-form-query($doc-type, $query-name)
  let $log := if ($cfg:D) then xdmp:log(text{ "local:get-result, $code-with-prolog = ", $code-with-prolog }) else ()

  let $excludeDeleted :=
    if ( map:get( $cfg:getRequestFieldsMap, "go" ) = "1") then
      ( map:get( $cfg:getRequestFieldsMap, "excludedeleted" )  = "1" )
    else
      fn:true()

  let $excludeVersions :=
    if ( map:get( $cfg:getRequestFieldsMap, "go" ) = "1") then
      ( map:get( $cfg:getRequestFieldsMap, "excludeversions" )  = "1" )
    else
      fn:true()

  let $user-q :=
    local:xdmpEval(
      $code-with-prolog,
      (xs:QName("params"), $cfg:getRequestFieldsMap),
      $database
    )

  let $log := if ($cfg:D) then xdmp:log(text{ "local:get-result, $user-q = ", $user-q }) else ()

  let $additional-query := cts:and-query(($user-q))(:should add deleted versions and excluded verisons - removed for now :)

  let $searchParams := map:map()

  let $_ :=
    (
      map:put($searchParams, "id", map:get($cfg:getRequestFieldsMap, "id")),
      map:put($searchParams, "searchText", map:get($cfg:getRequestFieldsMap,"searchText")),
      map:put($searchParams, "page", "1"),
      map:put($searchParams, "facet", ()),
      map:put($searchParams, "pagenumber", map:get($cfg:getRequestFieldsMap, "pagenumber")),
      map:put($searchParams, "selectedfacet", map:get($cfg:getRequestFieldsMap, "selectedfacet")),
      map:put($searchParams, "additionalquery", $additional-query),

      map:put($searchParams, "database", $database),
      map:put($searchParams, "docType", $doc-type),
      map:put($searchParams, "queryName", $query-name),
      map:put($searchParams, "viewName", $view-name)
      (:map:put($searchParams, "facets", local:build-facets($doc-type)):)
    )

  let $log :=
    if ($cfg:D) then
    (
      xdmp:log(text{ "$searchParams" })
      ,
      for $key in map:keys($searchParams)
      let $val := map:get($searchParams, $key)
      return
        xdmp:log(text{ $key, " = ",
          if ($val instance of element()*) then
            xdmp:describe($val, (), ())
          else
            fn:string($val)
        })
    )
    else
      ()

  let $ret := search-lib:search($searchParams,$database,($export-csv eq "true"))
  let $_ := if ( $cfg:D ) then
              xdmp:log(("Returned from search-lib",$ret))
            else
              ()
  return $ret
};

declare function local:get-json(){

  (:
    <output>
      <result-count>{search-lib:result-count($search-response)}</result-count>
      <current-page>{$page}</current-page>
      <page-count>{search-lib:page-count($search-response)}</page-count>
      <results>{$results}</results>
    </output>
  :)

  let $result := local:get-result()

  return 
    if (xs:string($result/result-count) = "0") then
      '{"result-count":"0"}'
    else
      let $results-json :=
        for $r in $result/results/result
        let $json := for $p in $r/part
            return if(fn:count($p/value) > 1) then
                     let $values := $p/value/node() ! fn:concat('"',fn:replace(fn:replace(xdmp:quote(.),'"','\\"'),"'","&apos;"),'"')
                     return fn:concat('"',$p/name,'":',to-json:seq-to-array-json($values))                 
            else    
                     let $value := fn:replace(fn:replace(xdmp:quote($p/value/node()),'"','\\"'),"'","&apos;")
                     return fn:concat('"',$p/name,'":"',$value,'"')
        let $r-json := fn:string-join($json,",")
        return fn:concat("{",$r-json,"}")
      let $results-json := to-json:seq-to-array-json($results-json)
      let $results-header-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($result/result-headers/header))
      let $output := 
        <output>
          <result-count>{$result/result-count}</result-count>
          <current-page>{$result/current-page}</current-page>
          <page-count>{$result/page-count}</page-count>
          <display-order>{$result/display-order}</display-order>
          <results-header>{$results-header-json}</results-header>
          <max-export-records>{$cfg:max-export-records}</max-export-records>
          <results>{$results-json}</results>
        </output>
      let $json := to-json:xml-obj-to-json($output)
      let $_ := if ( $cfg:D ) then
                    xdmp:log(("Search result JSON",$json))
                else
                    ()
      return $json
  };
  
declare function local:get-csv(){

  let $result := local:get-result()
  let $_:=xdmp:log($result)
  let $result-csv:= 
    if (xs:string($result/result-count) = "0") then
      'No Results'
    else
        for $r in $result/results/result
        let $csv := for $p in $r/part
            return if(fn:count($p/value) > 1) then
                     let $values := $p/value/node() ! fn:concat('"',fn:replace(fn:replace(xdmp:quote(.),'"','\\"'),"'","&apos;"),'"')
                     return fn:concat('"',fn:string-join($values, "|"),'"')                
            else    
                     let $value := fn:replace(fn:replace(xdmp:quote($p/value/node()),'"','\\"'),"'","&apos;")
                     return fn:concat('"',$value,'"')
        return fn:string-join($csv,",")
        let $headers:=fn:string-join($result/result-headers/header, ",")
   let $result-csv:=fn:string-join(($headers,$result-csv),"&#10;")     
     
   return $result-csv     
  };
let $_ := xdmp:log("FROM: /server/endpoints/adhoc/api-adhoc-search.xqy","debug")
let $export-csv := map:get($cfg:getRequestFieldsMap, "exportCsv")
 
return
       if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user())) then
            if($export-csv eq "true") then
                local:get-csv()
            else 
                (local:get-json())
        else (xdmp:set-response-code(401,"User is not authorized."))
