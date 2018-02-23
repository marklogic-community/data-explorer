xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";

declare function local:get-query-view() {
    let $queryName := map:get($cfg:getRequestFieldsMap, "queryName")
    let $docType := map:get($cfg:getRequestFieldsMap, "docType")
    let $viewName := map:get($cfg:getRequestFieldsMap, "viewName")
    let $insertView := map:get($cfg:getRequestFieldsMap, "insertView") = "true"
    let $_ := if ( fn:empty($queryName )) then fn:error(xs:QName("ERROR"),"$queryName may not be empty") else ()
    let $_ := if ( fn:empty($docType )) then fn:error(xs:QName("ERROR"),"$docType may not be empty") else ()
    let $queryDoc := /formQuery[@version=$const:SUPPORTED-VERSION and queryName=$queryName and documentType=$docType]
    let $_ := if ( fn:empty($queryDoc)) then
        fn:error(xs:QName("ERROR"),"Query '"||$queryName||"' and DocType '"||$docType||"' not found.") else ()
    let $queryMode := fn:string-length(fn:normalize-space($viewName)) = 0 and fn:not($insertView)
    let $viewName := if (fn:string-length(fn:normalize-space($viewName)) = 0) then
                        $const:DEFAULT-VIEW-NAME
                     else
                        $viewName
    let $view := $queryDoc/views/view[name=$viewName]
    let $_ := if ( fn:empty($view)) then
                  fn:error(xs:QName("ERROR"),"View '"||$viewName||"' not found.")
              else ()
    let $json :=   json:object()
    =>map:with("type",if ($queryMode) then 'Query' else 'View')
    =>map:with("queryName", $queryDoc/queryName/fn:string())
    =>map:with("viewName",$view/name/fn:string())
    =>map:with("bookmarkLabel",$view/bookmarkLabel/fn:string())
    =>map:with("database",$queryDoc/database/fn:string())
    =>map:with("displayOrder",$view/displayOrder/fn:string())
    =>map:with("rootElement",$queryDoc/documentType/fn:string())
    =>map:with("prefix",$queryDoc/documentType/@prefix)
    =>map:with("namespaces",array-node{
        for $ns in $queryDoc/namespaces/namespace
        return json:object()
        =>map:with("abbrv",$ns/abbr/fn:string())
        =>map:with("uri",$ns/uri/fn:string())})
    =>map:with("possibleRoots",array-node{
        for $pr in $queryDoc/possibleRoots/possibleRoot/fn:string()
          return $pr})
    =>map:with("fields",array-node{
        for $field in $queryDoc/formLabels/formLabel
            let $id := $field/@id
            let $search-entry := $queryDoc/searchFields/searchField[@id=$id]
            let $result-entry := $view/resultFields/resultField[@id=$id]
            let $mode :=
            if ( $insertView ) then
                  "none"
            else if ( (fn:not(fn:empty($search-entry)) and fn:not(fn:empty($result-entry))) ) then
                     "both"
            else if ( (fn:not(fn:empty($search-entry)))) then
                    "query"
                else if ( (fn:not(fn:empty($result-entry)))) then
                        "view"
                    else
                        "none"
            let $label := switch ($mode)
                            case "query" return $search-entry/@label
                            case "both" return $search-entry/@label
                            case "view" return $result-entry/@label
                            case "none" return ""
                            default return fn:error(xs:QName("ERROR"),"Error mode='"||$mode||"' unknown.")
            return json:object()
            =>map:with("elementName",functx:substring-after-last($field/@expr,"/"))
            =>map:with("title",$label)
            =>map:with("includeMode",$mode)
            =>map:with("dataType",$field/@dataType)
            =>map:with("xpathNormal",$field/@expr)})
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (local:get-query-view())
else (xdmp:set-response-code(401, "User is not authorized."))
