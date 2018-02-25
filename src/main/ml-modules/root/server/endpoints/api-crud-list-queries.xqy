xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";

declare function local:get-queries() {
    let $offset := xs:integer(map:get($cfg:getRequestFieldsMap, "startOffset"))
    let $pageSize := xs:integer(map:get($cfg:getRequestFieldsMap, "pageSize"))
    let $_ := if ( $offset < 1 ) then fn:error(xs:QName("ERROR"),"$offset="||$offset||" may not be smaller than 1") else ()
    let $_ := if ( $pageSize < 1 ) then fn:error(xs:QName("ERROR"),"$pageSize="||$pageSize||" may not be smaller than 1") else ()
    (: For queries we only select the query which has a default view. This is needed in case of edit. :)
    let $docs :=  /formQuery[@version=$const:SUPPORTED-VERSION]
    let $total := fn:count($docs)
    let $json :=   json:object()
    let $_ := map:put($json,"result-count",$total)
    let $_ := map:put($json,"rows",array-node {
        for $i in $docs[$offset to (-1 + $offset + $pageSize)]
        let $j := json:object()
        let $_ := map:put($j,"name", $i/queryName/fn:string())
        let $_ := map:put($j,"database", $i/database/fn:string())
        let $_ := map:put($j,"docType", $i/documentType/fn:string())
        return $j
    })
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in() and ( check-user-lib:is-wizard-user()))
then (local:get-queries())
else (xdmp:set-response-code(401, "User is not authorized."))
