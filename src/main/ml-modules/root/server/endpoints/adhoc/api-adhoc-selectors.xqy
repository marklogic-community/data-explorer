xquery version "1.0-ml";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"  at "/server/lib/config.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";

(: Expected output 

    ['Documents','other',....]
:)
(: address.com:port/api/adhoc/:database/:doctype :)
declare function local:get-doctypes-json($db as xs:string){
    let $doctypes := lib-adhoc:get-doctypes($db)

    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($doctypes))

    return $array-json
};
declare function local:get-queries-views-json($db as xs:string, $doctype as xs:string){
    let $queries := lib-adhoc:get-query-names($db,$doctype)
    let $views 	 := lib-adhoc:get-view-names($db,$doctype)
    let $queries-array-sequence := 
        for $q in $queries
            let $form-query-doc := cfg:get-form-query($doctype, $q)
            let $form-items := lib-adhoc:get-query-form-items($form-query-doc)
            let $options := to-json:seq-to-array-json($form-items ! to-json:xml-obj-to-json(.))
             return to-json:xml-obj-to-json(
                <output>
                    <query>{$q}</query>
                    <form-options>{ $options }</form-options>
                </output>)

    let $queries-json := to-json:seq-to-array-json($queries-array-sequence)
    let $views-json   := to-json:seq-to-array-json(to-json:string-sequence-to-json($views))
    
    let $json := to-json:xml-obj-to-json(<output><queries>{$queries-json}</queries><views>{$views-json}</views></output>)
    return $json
};

declare function local:get-json(){
	let $path 	 := xdmp:get-original-url()
	let $tokens  := fn:tokenize($path, "/")

	let $db 	 := $tokens[4] (:Since there can be multiple databases with name variations but same doctypes/views:)
	let $doctype := xdmp:url-decode( $tokens[5] )

	let $output :=
		if (fn:empty($doctype) or $doctype = "") then
			local:get-doctypes-json($db)
		else
			local:get-queries-views-json($db,$doctype)
    let $_ := ll:trace-details(("Returning Selector JSON:",$output))
    return $output
};

let $_ := ll:trace("FROM: /server/endpoints/adhoc/api-adhoc-selectors.xqy")
return
       if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user())) then
          (local:get-json())
        else (xdmp:set-response-code(401,"User is not authorized."))
