xquery version "1.0-ml";
import module namespace detail-lib = "http://www.marklogic.com/data-explore/lib/detail-lib" at "/server/lib/detail-lib.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";

declare function local:get-xml(){
    let $path := xdmp:get-original-url()
    let $tokens := fn:tokenize($path, "/")
    let $db 	:= $tokens[4]
    let $first-part := fn:concat("/api/get-xml-doc/",$db,"/")
    let $uri 	:= fn:substring-after($path,$first-part)
    return 
    	if (fn:count($tokens) > 4) then
    		if (detail-lib:database-exists($db)) then
                let $doc :=detail-lib:get-document($uri,$db)/element()
    			return (xdmp:set-response-content-type("text/xml"),$doc)
    		else
    			(xdmp:set-response-code(400,fn:concat("Invalid Database:",$db)))
        else
        	(xdmp:set-response-code(400,"URI Parameter count too low"))
};
let $_ := ll:trace("FROM: /server/endpoints/api-get-xml-doc.xqy")
return
local:get-xml()