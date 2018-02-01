xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace riu = "http://marklogic.com/data-explore/lib/range-index-utils" at "/server/lib/range-index-utils.xqy";


declare function local:get-json() {
  let $database := map:get($cfg:getRequestFieldsMap, "database")
  let $index := map:get($cfg:getRequestFieldsMap, "rangeIndex")
  let $match-text := map:get($cfg:getRequestFieldsMap, "qtext")
  let $values := riu:match-index-values($match-text, $database, $index, 10)

  let $json := json:object()

  return (
    map:put($json, "values", json:to-array($values)),
    xdmp:quote($json)
  )
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user())) 
then (local:get-json())
else (xdmp:set-response-code(401, "User is not authorized."))
