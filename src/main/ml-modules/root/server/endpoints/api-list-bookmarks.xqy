xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";

declare function local:get-bookmarks() {
    let $json :=   json:object()
    let $_ := map:put($json,"bookmarks",array-node {
        for $view in /formQuery[@version=$const:SUPPORTED-VERSION]/views/view[fn:string-length(fn:normalize-space(bookmarkLabel/fn:string()))>0]
        order by $view/bookmarkLabel/fn:string() ascending
        return
            let $query-doc := fn:root($view)/formQuery
            let $json := json:object()
            let $_ := map:put($json,"database", $query-doc/database/fn:string())
            let $_ := map:put($json,"queryName", $query-doc/queryName/fn:string())
            let $_ := map:put($json,"docType", $query-doc/documentType/fn:string())
            let $_ := map:put($json,"viewName",$view/name/fn:string())
            let $_ := map:put($json,"bookmarkLabel",$view/bookmarkLabel/fn:string())
            return $json
    })
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in())
then (local:get-bookmarks())
else (xdmp:set-response-code(401, "User is not authorized."))
