xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
declare option xdmp:mapping "false";
declare function local:get-views() {
    let $filter-default := xs:boolean(map:get($cfg:getRequestFieldsMap, "filterDefaultView"))
    let $filter-default := if ( fn:empty($filter-default)) then fn:true() else $filter-default
    let $offset := xs:integer(map:get($cfg:getRequestFieldsMap, "startOffset"))
    let $pageSize := xs:integer(map:get($cfg:getRequestFieldsMap, "pageSize"))
    let $queryName := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "queryName"))
    let $docType := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "docType"))
    let $offset := if ( fn:empty($offset) or $offset < 1 ) then 1 else $offset
    let $pageSize := if ( fn:empty($pageSize) or $pageSize < 1 ) then $const:INTEGER_MAX else $pageSize
    let $docs := cfg:get-form-query($docType,$queryName)/views/view/name/fn:string()
    let $viewNames := if ( $filter-default) then
                          fn:filter(function($v) { $v != $const:DEFAULT-VIEW-NAME},$docs)
                      else
                          $docs
    let $total-count := fn:count($viewNames)
    let $json :=   json:object()
    let $_ := map:put($json,"result-count",$total-count)
    let $_ := map:put($json,"views",array-node {
                        for $viewName in $viewNames[$offset to (-1 + $offset + $pageSize)]
                        let $j := json:object()
                        let $_ := map:put($j,"viewName", $viewName)
                        return $j
                    })
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in() and check-user-lib:is-search-user())
then (local:get-views())
else (xdmp:set-response-code(401, "User is not authorized."))
