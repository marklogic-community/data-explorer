xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace riu = "http://marklogic.com/data-explore/lib/range-index-utils" at "/server/lib/range-index-utils.xqy";
declare option xdmp:mapping "false";

declare function local:get-json() {
  let $queryName := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "queryName"))
  let $docType := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "docType"))
  let $_ := xdmp:log(("JOS DOCTYPE ",$docType,"queryName",$queryName))
  let $query-doc := cfg:get-form-query($docType,$queryName)
  let $index := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "rangeIndex"))
  let $match-text := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "qtext"))
  let $_ := xdmp:log("MATCH-INDEX-VALUES")
  let $values := riu:match-index-values($match-text, $query-doc, $index, 10)

  let $json := json:object()

  return (
    map:put($json, "values", json:to-array($values)),
    xdmp:quote($json)
  )
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user())) 
then (local:get-json())
else (xdmp:set-response-code(401, "User is not authorized."))
