xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";
declare option xdmp:mapping "false";
declare function local:get-type-discriminators() {
    let $database := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "database"))
    let $_ := if ( fn:empty($database )) then fn:error(xs:QName("ERROR"),"database parameter may not be empty") else ()
    let $doctypes := lib-adhoc:get-doctypes($database)
    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($doctypes))
    return $array-json
};

let $_ := ll:trace("FROM: /server/endpoints/api-crud-list-type-discriminators.xqy")
return if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (local:get-type-discriminators())
else (xdmp:set-response-code(401, "User is not authorized."))