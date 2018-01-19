xquery version "1.0-ml";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;

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
        let $options := to-json:seq-to-array-json(to-json:string-sequence-to-json(lib-adhoc:get-query-form-items($doctype,$q)))
        return to-json:xml-obj-to-json(<output><query>{$q}</query><form-options>{$options}</form-options></output>)

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

	return 
		if (fn:empty($doctype) or $doctype = "") then
			local:get-doctypes-json($db)
		else
			local:get-queries-views-json($db,$doctype)
};
let $_ := xdmp:log("FROM: /server/endpoints/adhoc/api-adhoc-selectors.xqy","debug")
return
       if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user())) then
          (local:get-json())
        else (xdmp:set-response-code(401,"User is not authorized."))
