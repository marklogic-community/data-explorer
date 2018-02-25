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
    let $_ := map:put($json,"type",if ($queryMode) then 'Query' else 'View')
    let $_ := map:put($json,"queryName", $queryDoc/queryName/fn:string())
    let $_ := map:put($json,"viewName",$view/name/fn:string())
    let $_ := map:put($json,"bookmarkLabel",$view/bookmarkLabel/fn:string())
    let $_ := map:put($json,"database",$queryDoc/database/fn:string())
    let $_ := map:put($json,"displayOrder",$view/displayOrder/fn:string())
    let $_ := map:put($json,"rootElement",$queryDoc/documentType/fn:string())
    let $_ := map:put($json,"prefix",$queryDoc/documentType/@prefix)
    let $_ := map:put($json,"namespaces",array-node{
        for $ns in $queryDoc/namespaces/namespace
        let $j := json:object()
        let $_ := map:put($j,"abbrv",$ns/abbr/fn:string())
        let $_ := map:put($j,"uri",$ns/uri/fn:string())
        return $j})
    let $_ := map:put($json,"possibleRoots",array-node{
        for $pr in $queryDoc/possibleRoots/possibleRoot/fn:string()
          return $pr})
    let $_ := map:put($json,"fields",array-node{
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
            let $j := json:object()
            let $_ := map:put($j,"elementName",functx:substring-after-last($field/@expr,"/"))
            let $_ := map:put($j,"title",$label)
            let $_ := map:put($j,"includeMode",$mode)
            let $_ := map:put($j,"dataType",$field/@dataType)
            let $_ := map:put($j,"xpathNormal",$field/@expr)
            return $j })
    return xdmp:to-json($json)
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (local:get-query-view())
else (xdmp:set-response-code(401, "User is not authorized."))
