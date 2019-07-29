xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";
declare option xdmp:mapping "false";


declare private function local:process-xml($collections,$database) {
  let $qnames := lib-adhoc:get-root-qnames($collections,$database)

  let $doc-types := for $qname in $qnames
  let $local-name := fn:local-name-from-QName($qname)
  let $ns := fn:namespace-uri-from-QName($qname)
  let $prefix := fn:prefix-from-QName($qname)
  let $prefix := if ( fn:empty($prefix) and fn:string-length(fn:normalize-space($ns))>0) then
    $const:DEFAULT-NAMESPACE-PREFIX
  else $prefix
  let $ns-info := if ( fn:string-length(fn:normalize-space($ns))>0 ) then
    " - "||$prefix||":"||$ns
  else ()
  let $doc-type := fn:concat("/", if (fn:string-length($prefix) le 0) then () else $prefix||":", $local-name,$ns-info)
  return object-node {
  "localName": $local-name,
  "ns": $ns,
  "docType": $doc-type
  }

  let $json := json:object()
  return (
    map:put($json, "docTypes", json:to-array($doc-types)),
    $json
  )
};

declare private function local:find-all-paths($node as node()?,$path) {
  for $i in $node/node()
    let $localname := fn:name($i)

    let $finalpath := fn:concat($path, "/", $localname)
    return
       if ($i instance of object-node() ) then
          (
            ($finalpath,local:find-all-paths ($i,$finalpath))
          )
        else if ($i instance of array-node()) then
            local:find-all-paths($i,$path)
          else
            ()
};

declare function local:process-json($database,$collections) {
  let $dt := xu:invoke-function(function() {
      let $collection-query := lib-adhoc:get-collection-query($collections)
      let $doc := cts:search(fn:doc(),$collection-query)[1]
      return ("/",local:find-all-paths($doc/node(),""))
  },
  <options xmlns="xdmp:eval">
  <database>{ xdmp:database($database) }</database>
  </options>
  )
  let $doc-types := $dt ! object-node {
                              "localName": fn:tokenize(.,"/")[last()],
                              "ns": "",
                              "docType": .
                              }
  let $json := json:object()
  return (
    map:put($json, "docTypes", json:to-array($doc-types)),
    $json
  )
};

declare function local:process() {
  try {
    let $database := map:get($cfg:getRequestFieldsMap, "database")
    let $collections := map:get($cfg:getRequestFieldsMap, "collections")
    let $fileType := map:get($cfg:getRequestFieldsMap, "fileType")
    return if ( $fileType eq "0") then
        local:process-xml($database,$collections)
    else
        local:process-json($database,$collections)
  }
  catch($exception) {
    let $_ := ll:trace($exception)
    return if ($exception/*:code eq "XDMP-NOSUCHDB")
    then xdmp:set-response-code(400, "Specified database is incorrect or does not exist.")
    else $exception
  }
};


if (check-user-lib:is-logged-in() and check-user-lib:is-wizard-user()) 
then local:process()
else xdmp:set-response-code(401, "User is not authorized.")
