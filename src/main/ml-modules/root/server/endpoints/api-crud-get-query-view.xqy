xquery version "1.0-ml";

import module namespace tde-lib = "http://www.marklogic.com/data-explore/lib/tde-lib" at "/server/lib/tde-lib.xqy";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
import module namespace riu = "http://marklogic.com/data-explore/lib/range-index-utils" at "/server/lib/range-index-utils.xqy";
declare namespace db = "http://marklogic.com/xdmp/database";
declare option xdmp:mapping "false";
declare function local:get-query-view() {
    let $queryName := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "queryName"))
    let $docType := xdmp:url-decode(map:get($cfg:getRequestFieldsMap, "docType"))
    let $viewName := map:get($cfg:getRequestFieldsMap, "viewName")
    let $viewName := if ( fn:empty($viewName) )  then () else xdmp:url-decode($viewName)
    let $viewMode := fn:string-length(fn:normalize-space($viewName)) > 0
    let $_ := if ( fn:empty($queryName )) then fn:error(xs:QName("ERROR"),"$queryName may not be empty") else ()
    let $_ := if ( fn:empty($docType )) then fn:error(xs:QName("ERROR"),"$docType may not be empty") else ()
    let $queryDoc := cfg:get-form-query($docType,$queryName)
    let $_ := if ( fn:empty($queryDoc)) then
        fn:error(xs:QName("ERROR"),"Query '"||$queryName||"' and DocType '"||$docType||"' not found.") else ()
    let $viewName := if (fn:not($viewMode)) then
                        $const:DEFAULT-VIEW-NAME
                     else
                        $viewName
    let $view := $queryDoc/views/view[name=$viewName]
    let $_ := if ( fn:empty($view)) then
                  fn:error(xs:QName("ERROR"),"View '"||$viewName||"' not found.")
              else ()
    let $json :=   json:object()
    let $_ := map:put($json,"collections", $queryDoc/collections/fn:string())
    let $_ := map:put($json,"fileType", $queryDoc/fileType/fn:string())
    let $_ := map:put($json,"queryName", $queryDoc/queryName/fn:string())
    let $_ := map:put($json,"viewName",$view/name/fn:string())
    let $_ := map:put($json,"bookmarkLabel",$view/bookmarkLabel/fn:string())
    let $_ := map:put($json,"createTDE",tde-lib:has-tde($queryDoc,$view))
    let $_ := map:put($json,"database",$queryDoc/database/fn:string())
    let $_ := map:put($json,"displayOrder",$view/displayOrder/fn:string())
    let $_ := map:put($json,"rootElement",$queryDoc/documentType/fn:string())
    let $_ := map:put($json,"prefix",$queryDoc/documentType/@prefix)
    let $_ := map:put($json,"formLabels",array-node{
        for $option in $queryDoc/searchFields/searchField
        let $dict := $queryDoc/formLabels/formLabel[@id=$option/@id]
        let $form-field := fn:tokenize($dict/@expr, "/")[fn:last()]
        let $range-index := riu:get-index($queryDoc, $form-field)
        let $dataType := fn:string($dict/@dataType)
        let $label := fn:string($option/@label)
        return
            let $j := json:object()
            let $_ := map:put($j,"dataType",$dataType)
            let $_ := map:put($j,"label",$label)
            let $_ := if (fn:empty($range-index)) then () else (
                     map:put($j,"rangeIndex",$form-field),
                     map:put($j,"scalarType",$range-index/db:scalar-type/fn:string())
                        )
            return $j
        })
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
            if ( fn:not($viewMode) and (fn:not(fn:empty($search-entry)) and fn:not(fn:empty($result-entry))) ) then
                     "both"
            else if ( fn:not($viewMode) and (fn:not(fn:empty($search-entry)))) then
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

if (check-user-lib:is-logged-in() and check-user-lib:is-search-user())
then (local:get-query-view())
else (xdmp:set-response-code(401, "User is not authorized."))
