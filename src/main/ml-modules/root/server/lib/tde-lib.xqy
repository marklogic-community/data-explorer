xquery version "1.0-ml";

module namespace tde-lib = "http://www.marklogic.com/data-explore/lib/tde-lib";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";
import module namespace tde = "http://marklogic.com/xdmp/tde" at "/MarkLogic/tde.xqy";

declare option xdmp:mapping "false";

declare function tde-lib:delete-all-tdes-for-query($form-query as element(formQuery)) as xs:string* {
    tde-lib:internal-delete-tdes-for-query-or-view($form-query,())
};

declare function tde-lib:delete-tde-for-query-view($form-query as element(formQuery),$view as xs:string) as xs:string* {
    tde-lib:internal-delete-tdes-for-query-or-view($form-query,$view)
};

declare function tde-lib:has-tde($form-query as element(formQuery),$view as element(view)) as xs:boolean {
    let $database := $form-query/database/fn:string()
    let $schemas-database := xdmp:schema-database(xdmp:database($database))
    return xu:invoke-function(function() {
        fn:exists(fn:doc(tde-lib:get-tde-uri($form-query,$view/name/fn:string())))
    },<options xmlns="xdmp:eval">
        <update>false</update>
        <database>{$schemas-database}</database>
    </options>)
};
declare function tde-lib:create-or-update-tde($create-tde as xs:boolean,$form-query as element(formQuery),$view as element(view)) as empty-sequence()  {
    if (fn:not($create-tde)) then
                 if ( tde-lib:has-tde($form-query,$view)) then
                       let $_ := tde-lib:delete-tde-for-query-view($form-query,$view/name/fn:string())
                       return ()
                 else ()
              else (
                    let $schema-name := "dataexplorer"
                    let $view-name := $form-query/queryName/fn:string()||"_"||$view/name/fn:string()
                    let $context := $form-query/documentType/fn:string()
                    let $namespaces := $form-query/namespaces/namespace
                    let $path-namespaces := if (fn:empty($namespaces)) then ()
                    else
                        for $ns in $namespaces
                        let $abbr := $ns/abbr/fn:string()
                        let $uri := $ns/uri/fn:string()
                        return <path-namespace xmlns="http://marklogic.com/xdmp/tde">
                            <prefix>{$abbr}</prefix>
                            <namespace-uri>{$uri}</namespace-uri>
                        </path-namespace>
                    let $path-namespaces := if ( fn:empty($path-namespaces)) then ()
                    else
                        <path-namespaces xmlns="http://marklogic.com/xdmp/tde">
                            {$path-namespaces}
                        </path-namespaces>
                    let $cols := $view/resultFields/resultField
                    let $cols := for $col in $cols order by $col/@id/fn:string() return $col
                    let $collections := fn:tokenize($form-query/collections/fn:string(),",")
                    let $tde-collections := if ( fn:empty($collections)) then () else <collections xmlns="http://marklogic.com/xdmp/tde"><collections-and>{$collections ! <collection>{.}</collection>}</collections-and></collections>
                    let $tde-cols :=  for $col in $cols
                                        let $expression := $form-query/formLabels/formLabel[@id=$col/@id]/@exec_expr
                                        let $expression := if (fn:starts-with($expression, $context)) then "."||fn:substring($expression,fn:string-length($context)+1) else $expression
                                        let $label := $col/@label/fn:string()
                                        return <column xmlns="http://marklogic.com/xdmp/tde">
                                            <name>{fn:replace($label,"\.","_")}</name>
                                            <scalar-type>string</scalar-type>
                                            <val>{$expression}</val>
                                            <nullable>true</nullable>
                                        </column>
                    let $tde:=   <template xmlns="http://marklogic.com/xdmp/tde">
                        <context>{$context}</context>
                        {$tde-collections}
                        {$path-namespaces}
                        <rows>
                            <row>
                                <schema-name>{$schema-name}</schema-name>
                                <view-name>{$view-name}</view-name>
                                <view-layout>sparse</view-layout>
                                <columns>
                                    { $tde-cols }
                                </columns>
                            </row>
                        </rows>
                    </template>
                    let $database := $form-query/database/fn:string()
                    let $_ := xu:invoke-function(function() { 
                        tde:template-insert(tde-lib:get-tde-uri($form-query,$view/name/fn:string()),$tde)
                    },<options xmlns="xdmp:eval">
                        <update>true</update>
                        <database>{xdmp:database($database)}</database>
                    </options>)
                    return ()
        )
};

(: Private functions :)

declare private function tde-lib:get-tde-uri($form-query as element(formQuery),$view as xs:string?) as xs:string {
    "/dataexplorer-"||$form-query/queryName/fn:string()||"-"||$view
};

declare private function tde-lib:internal-delete-tdes-for-query-or-view($form-query,$view as xs:string?)  as xs:string* {
    let $database := $form-query/database/fn:string()
    let $schemas-database := xdmp:schema-database(xdmp:database($database))
    let $uris := xdmp:invoke-function(function() {
        let $uris := if ( fn:empty($view)) then
            let $pattern := tde-lib:get-tde-uri($form-query,())||"*"
            return cts:uri-match($pattern)
        else
            let $uri := tde-lib:get-tde-uri($form-query,$view)
            return if ( fn:exists(fn:doc($uri))) then
                $uri
            else
                ()
        let $_ := $uris ! xdmp:document-delete(.)
        return $uris
    },<options xmlns="xdmp:eval">
        <update>true</update>
        <database>{$schemas-database}</database>
    </options>)
    return $uris
};
