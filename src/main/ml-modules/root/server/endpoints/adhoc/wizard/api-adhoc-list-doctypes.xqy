xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";


declare function local:process() {
  try {
    let $database := map:get($cfg:getRequestFieldsMap, "database")
    let $qnames := lib-adhoc:get-root-qnames($database)

    let $doc-types := for $qname in $qnames
      let $local-name := fn:local-name-from-QName($qname)
      let $ns := fn:namespace-uri-from-QName($qname)
      let $doc-type := fn:concat("/", if (fn:string-length($ns) le 0) then () else "*:", $local-name) 
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
