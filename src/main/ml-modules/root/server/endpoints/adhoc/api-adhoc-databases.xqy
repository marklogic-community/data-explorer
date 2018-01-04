xquery version "1.0-ml";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;

(: Expected output 

    ['Documents','other',....]
:)

declare function local:get-json(){
    let $databases := 
    	for $d in lib-adhoc:get-databases()
    	where fn:not(fn:contains(fn:lower-case($d),"modules"))
    	return $d


    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($databases))
    return $array-json
};

let $_ := xdmp:log("FROM: /server/endpoints/adhoc/api-adhoc-databases.xqy","debug")
return
       if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user())) then
          (local:get-json())
        else (xdmp:set-response-code(401,"User is not authorized."))
