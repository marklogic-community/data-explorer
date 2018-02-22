xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";

declare function local:get-views() {
    let $offset := xs:integer(map:get($cfg:getRequestFieldsMap, "startOffset"))
    let $pageSize := xs:integer(map:get($cfg:getRequestFieldsMap, "pageSize"))
    let $queryName := map:get($cfg:getRequestFieldsMap, "queryName")
    let $docType := map:get($cfg:getRequestFieldsMap, "docType")
    let $_ := if ( fn:empty($queryName )) then fn:error(xs:QName("ERROR"),"$queryName may not be empty") else ()
    let $_ := if ( fn:empty($docType )) then fn:error(xs:QName("ERROR"),"$docType may not be empty") else ()
    (: Filter out the default view name :)
    let $viewNames := fn:filter(function($v) { $v != $const:DEFAULT-VIEW-NAME},//formQuery[queryName=$queryName and documentType=$docType]/views/view/name/fn:string())
    let $total-count := fn:count($viewNames)
    let $json :=   json:object()
                    =>map:with("result-count",$total-count)
                    =>map:with("views",array-node {
                        for $viewName in $viewNames[$offset to (-1 + $offset + $pageSize)]
                        return json:object()
                        =>map:with("viewName", $viewName)
                    })
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (local:get-views())
else (xdmp:set-response-code(401, "User is not authorized."))
