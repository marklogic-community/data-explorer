xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
declare option xdmp:mapping "false";
declare function local:remove-view() {
    let $queryName := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "queryName"))
    let $docType := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "docType"))
    let $viewName := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "viewName"))
    let $_ := if ( fn:empty($queryName) or $queryName = '' ) then fn:error(xs:QName("ERROR"),"QueryName may not be empty.") else ()
    let $_ := if ( fn:empty($docType) or $docType = '' ) then fn:error(xs:QName("ERROR"),"DocType may not be empty.") else ()
    let $_ := if ( fn:empty($viewName) or $viewName = '' ) then fn:error(xs:QName("ERROR"),"ViewName may not be empty.") else ()
    let $doc := cfg:get-form-query($docType,$queryName)
    let $view-node := $doc//views/view[name=$viewName]
    let $_ := xdmp:node-delete($view-node)
    return ()
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (local:remove-view())
else (xdmp:set-response-code(401, "User is not authorized."))
