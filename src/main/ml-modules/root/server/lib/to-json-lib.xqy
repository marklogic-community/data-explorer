xquery version "1.0-ml";
module namespace to-json = "http://marklogic.com/data-explore/lib/to-json";

import module namespace json = "http://marklogic.com/xdmp/json"
    at "/MarkLogic/json/json.xqy";

declare function to-json:to-json($xml){
	let $custom :=
     let $config := json:config("custom")
     return 
       (map:put($config, "array-element-names",
                 ("text","point","value","operator-state",
                  "annotation","uri","qtext")),
        map:put($config, "element-namespace", 
                 "http://marklogic.com/appservices/search"),
        map:put($config, "element-namespace-prefix", "search"),
        map:put($config, "attribute-names",("warning","name")),
        map:put($config, "full-element-names",
                 ("query","and-query","near-query","or-query")),
        map:put($config, "json-children","queries"), 
        $config)        
    return 
        json:transform-to-json(
            $xml,
            $custom
        )
};

declare function to-json:string-sequence-to-json($items as xs:string*){
    let $joined := fn:string-join($items,'","')
    return if ($joined = '') then '' else fn:concat('"',$joined,'"')
};

declare function to-json:value-to-json($str as xs:string){
    let $firstChar := fn:substring($str,1,1)
    let $lastChar := fn:substring($str,fn:string-length($str),1)
    return if (($firstChar = "{" and $lastChar = "}") 
            or ($firstChar = ('"',"'") and $firstChar = $lastChar) or
            ($firstChar = "[" and $lastChar = "]")) then
                $str
            else
                fn:concat('"',$str,'"')
};

declare function to-json:xml-obj-to-json($node as node()){
    let $nodes := for $n in $node/*
      return fn:concat('"',xs:string(fn:node-name($n)),'":',to-json:value-to-json($n))
    return fn:concat("{",fn:string-join($nodes,","),"}")
};

declare function to-json:seq-to-array-json($seq as xs:string*){
    let $array-inside := fn:string-join($seq,",")
    return fn:concat('[',$array-inside,']')
};