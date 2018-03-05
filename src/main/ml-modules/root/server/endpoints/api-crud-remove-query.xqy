xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
declare option xdmp:mapping "false";
declare function local:remove-query() {
    let $queryName := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "queryName"))
    let $docType := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "docType"))
    let $_ := if ( fn:empty($queryName) or $queryName = '' ) then fn:error(xs:QName("ERROR"),"QueryName may not be empty.") else ()
    let $_ := if ( fn:empty($docType) or $docType = '' ) then fn:error(xs:QName("ERROR"),"DocType may not be empty.") else ()
    let $docs := cfg:get-form-query($docType,$queryName)
    let $_ := $docs ! xdmp:document-delete(fn:base-uri(.))
    return ()
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (local:remove-query())
else (xdmp:set-response-code(401, "User is not authorized."))
