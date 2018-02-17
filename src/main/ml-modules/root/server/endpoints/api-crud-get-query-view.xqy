xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
declare function local:get-query-view() {
    let $mode := map:get($cfg:getRequestFieldsMap, "mode")
    let $name := map:get($cfg:getRequestFieldsMap, "name")
    let $_ := if ( fn:empty($name )) then fn:error(xs:QName("ERROR"),"$name may not be empty") else ()
    let $_ := if ( $mode != 'query' and $mode != 'view' ) then fn:error(xs:QName("ERROR"),"$mode="||$mode||" should be 'query' or 'view") else ()
    let $doc := if ( $mode = 'query') then /formQuery[queryName=$name] else /view[viewName=$name]
    let $_ := if ( fn:empty($doc) ) then fn:error("Could not find "||$mode||" with name '"||$name||"'") else ()
    let $view := if ( $mode = 'query' ) then fn:doc(fn:substring-before(fn:base-uri($doc),"forms-queries")||'views/'||$doc/queryName/fn:string()||'-Default-View.xml') else $doc
    let $_ := if ( fn:empty($doc)) then fn:error("Could not find default view for query "||$name) else ()
    let $json :=   json:object()
    =>map:with("type",if ($mode = 'query') then 'Query' else 'View')
    =>map:with("queryViewName",if ($mode = 'query') then $doc/queryName/fn:string() else $doc/viewName/fn:string())
    =>map:with("database",$doc/database/fn:string())
    =>map:with("displayOrder",$view//displayOrder/fn:string())
    =>map:with("rootElement",$doc/documentType/fn:string())
    =>map:with("namespaces",array-node{
        for $ns in $view//namespace
        return json:object()
        =>map:with("abbrv",$ns/abbr/fn:string())
        =>map:with("uri",$ns/uri/fn:string())})
    =>map:with("fields",array-node{
        for $column in $view//columns/column
        return json:object()
        =>map:with("elementName",functx:substring-after-last($column//@expr,"/"))
        =>map:with("title",$column//@name)
        =>map:with("includeMode",$column//@mode)})
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user()))
then (local:get-query-view())
else (xdmp:set-response-code(401, "User is not authorized."))
