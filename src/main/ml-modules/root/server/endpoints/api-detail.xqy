xquery version "1.0-ml";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";   
import module namespace detail-lib = "http://www.marklogic.com/data-explore/lib/detail-lib" at "/server/lib/detail-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;

(: Expected output 

	{type:'DocumentType',permissions:[{'role':'test','method':'read'}],collections:['a','b'],text:'<root></root>',
      related:[
        {
          type:'Type A', items:[{uri:'abc.html',db:'Documents'}]
        }
      ]
    };

	:)
 declare function local:label-from-element-name($element-name as xs:string?) as xs:string? {
    
    fn:string-join(
                for $word in fn:tokenize(functx:camel-case-to-words($element-name," "), "-")
                return functx:capitalize-first(functx:trim($word))
                , " ")
    
   
 };

declare function local:render-document($node) {
    typeswitch($node)
        case text() return <span class="value">{$node}</span>
        case element() 
          return 
            if (fn:exists($node/text())) then 
              <div class="element">
                <span class="element-label">{local:label-from-element-name($node/name())}</span>
                {local:recurse($node)}
              </div>
            else if (fn:string-length($node/string()) > 0) then (:element with no direct content :)
               <div class="element-heading">
                <span class="element-label">{local:label-from-element-name($node/name())}</span>
                {local:recurse($node)}
               </div>
            else ()
        case attribute() return <div class="attribute"><span class="attribute-name">{fn:concat("@",$node/name())}</span><span class="attribute-value">{$node/fn:string()}</span></div>
        default return local:recurse($node)
};

declare function local:recurse($node) {
    for $child in ($node/node(),$node/@*)
    return
        local:render-document($child)
};


declare function local:get-json($uri as xs:string, $db as xs:string){
	let $doc 		 :=detail-lib:get-document($uri,$db)/element()
    let $rawDoc     := xdmp:quote(local:render-document(detail-lib:get-document($uri,$db)))
    let $docText    := fn:normalize-space(fn:replace(xdmp:quote($rawDoc),'"', '\\"'))
    let $docXml     := fn:normalize-space(fn:replace(xdmp:quote($doc),'"', '\\"'))
	let $doctype 	 := fn:local-name( $doc )
    let $collections :=detail-lib:get-collections($uri,$db)
	let $permissions :=detail-lib:get-permissions($uri,$db)
    let $triples := detail-lib:get-triples($uri, $db)
	let $related-map 	 :=detail-lib:find-related-items-by-document($doc,$db)
    let $related-items-json :=
        for $key in map:keys($related-map)
        let $values := to-json:seq-to-array-json(to-json:string-sequence-to-json(map:get($related-map,$key)))
        let $item := <item><type>{$key}</type><items>{$values}</items></item>

        return to-json:xml-obj-to-json($item)
    let $related-json := to-json:seq-to-array-json($related-items-json)
    let $permissions-json := to-json:seq-to-array-json(to-json:xml-obj-to-json($permissions))
    let $collections-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($collections))
    let $xml := 
        <output>
            <type>{$doctype}</type>
            <collections>{$collections-json}</collections>
            <permissions>{$permissions-json}</permissions>
            <triples>{ to-json:seq-to-array-json(for $t in $triples return xdmp:quote($t)) }</triples>
            <text>{$docText}</text>
            <xml>{$docXml}</xml>
            <related>{$related-json}</related>
        </output>

    let $json := to-json:xml-obj-to-json($xml)
	return $json
};

declare function local:get-details(){
    let $path := xdmp:get-original-url()
    let $tokens := fn:tokenize($path, "/")
    let $db 	:= xdmp:url-decode($tokens[4])
    let $first-part := fn:concat("/api/detail/",$db,"/")
    let $uri 	:= xdmp:url-decode(fn:substring-after($path,$first-part))
    return 
    	if (fn:count($tokens) > 4) then
    		if (detail-lib:database-exists($db)) then
    			(xdmp:set-response-code(200,"Success"),local:get-json($uri,$db))
    		else
    			(xdmp:set-response-code(400,fn:concat("Invalid Database:",$db)))
        else
        	(xdmp:set-response-code(400,"URI Parameter count too low"))
};
let $_ := xdmp:log("FROM: /server/endpoints/api-detail.xqy","debug")
return 
       if (check-user-lib:is-logged-in() and (check-user-lib:is-search-user() or check-user-lib:is-wizard-user())) then
          (local:get-details())
        else (xdmp:set-response-code(401,"User is not authorized."))