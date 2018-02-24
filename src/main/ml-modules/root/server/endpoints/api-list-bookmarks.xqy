xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";

declare function local:get-bookmarks() {
    let $json :=   json:object()
    =>map:with("bookmarks",array-node {
        for $view in /formQuery[@version=$const:SUPPORTED-VERSION]/views/view[fn:string-length(fn:normalize-space(bookmarkLabel/fn:string()))>0]
        order by $view/bookmarkLabel/fn:string() ascending
        return
            let $query-doc := fn:root($view)/formQuery
            let $json := json:object()
            =>map:with("database", $query-doc/database/fn:string())
            =>map:with("queryName", $query-doc/queryName/fn:string())
            =>map:with("docType", $query-doc/documentType/fn:string())
            =>map:with("viewName",$view/name/fn:string())
            =>map:with("bookmarkLabel",$view/bookmarkLabel/fn:string())
            return $json
    })
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in())
then (local:get-bookmarks())
else (xdmp:set-response-code(401, "User is not authorized."))
