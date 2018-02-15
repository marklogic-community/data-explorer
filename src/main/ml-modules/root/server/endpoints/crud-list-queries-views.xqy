xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";

declare function local:get-queries-views() {
    let $offset := xs:integer(map:get($cfg:getRequestFieldsMap, "startOffset"))
    let $pageSize := xs:integer(map:get($cfg:getRequestFieldsMap, "pageSize"))
    let $mode := map:get($cfg:getRequestFieldsMap, "mode")
    let $_ := if ( $offset < 1 ) then fn:error(xs:QName("ERROR"),"$offset="||$offset||" may not be smaller than 1") else ()
    let $_ := if ( $pageSize < 1 ) then fn:error(xs:QName("ERROR"),"$pageSize="||$pageSize||" may not be smaller than 1") else ()
    let $_ := if ( $mode != 'queries' and $mode != 'views' ) then fn:error(xs:QName("ERROR"),"$mode="||$mode||" should be 'queries' or 'views") else ()
    let $docs := if ( $mode = 'views' ) then /view else /formQuery
    let $total := fn:count($docs)
    let $json :=   json:object()=>map:with("result-count",$total)
                      =>map:with("rows",array-node {
        for $i in $docs[$offset to (-1 + $offset + $pageSize)]
        let $json := json:object()
        =>map:with("name", if ( $mode = 'views') then $i/viewName/fn:string() else $i/queryName/fn:string())
        =>map:with("database", $i/database/fn:string())
        =>map:with("docType", $i/documentType/fn:string())
        return $json
    })
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user()))
then (local:get-queries-views())
else (xdmp:set-response-code(401, "User is not authorized."))
