xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;




declare function local:getStructure($doc) {
  for $d in $doc/child::*
  return (xdmp:path($d), local:getStructure($d)) ! fn:replace(., "\[.*\]", "")
};

declare function local:registerNamespaces($node as node()) {
    let $ns-xquery :=
            <x>
            <![CDATA[

                import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
                import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
                import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 

                declare variable $node external;
                let $reserved-ns := ("http://www.w3.org/XML/1998/namespace")

                let $existing-map := $cfg:NS-MAP
                let $pref-map := map:map()
                let $_ := 
                  for $key in map:keys($existing-map) 
                  let $onlytext := fn:tokenize(map:get($existing-map, $key), "\d+")[1]
                  return 
                    if(map:get($pref-map,$onlytext)) then
                      map:put($pref-map, $onlytext, map:get($pref-map,$onlytext) + 1)
                    else map:put($pref-map, $onlytext, 1)

                let $new-map := map:map()
                let $_ :=
                    for $ns in functx:namespaces-in-use($node)[. ne $reserved-ns]
                    return
                        if(fn:string-length($ns) ge 1
                        and fn:not($ns eq $cfg:NS-IGNORE-LIST)) then
                        (

                            let $ns-prefix :=
                                fn:string-join(
                                  (
                                  for $word in tokenize($ns, '\W+')[. != '']
                                  return codepoints-to-string(string-to-codepoints($word)[1])
                                  )
                                  ,""
                                  )
                            let $ns-prefix :=
                              if(map:get($pref-map, $ns-prefix)) then
                              (  
                                 $ns-prefix||map:get($pref-map, $ns-prefix),
                                 map:put($pref-map, $ns-prefix, map:get($pref-map, $ns-prefix) + 1)
                              )
                              else 
                              (
                                $ns-prefix,
                                map:put($pref-map, $ns-prefix, 1)
                              )
                                 
                            return
                            if(fn:not(map:get($existing-map, $ns))) then
                              map:put($new-map, $ns, $ns-prefix)
                            else()
                            
                        )
                        else()

                return
                if(map:count($new-map) ge 1) then
                (
                    let $all-map := if(map:count($existing-map) ge 1) then
                                        ($existing-map + $new-map)
                                    else ($new-map)
                    let $doc :=
                        element namespaces{
                            $all-map
                        }
                    return
                    (
                        xu:document-insert($cfg:NS-URI,$doc)
                        ,
                        xdmp:set-server-field($cfg:NS-SERVER-FIELD, $all-map)
                    )
                )
                else()

            ]]>
            </x>/text()
    return
    xu:eval(
            $ns-xquery
            ,
            (xs:QName("node"),$node),
            <options xmlns="xdmp:eval">
                <isolation>different-transaction</isolation>
                <prevent-deadlocks>true</prevent-deadlocks>
            </options>
    )
};

declare function local:get-children-nodes($path, $node as node()) {


  let $results :=
      for $i in $node/node()
      let $ns := xs:string(fn:namespace-uri($i))
      let $root-ns-prefix-check := (cfg:getNamespacePrefix(xs:string(fn:namespace-uri(fn:root($i)))))
      let $root-ns-prefix := if($root-ns-prefix-check) then $root-ns-prefix-check||":" else ("")
      let $ns-prefix-check := (cfg:getNamespacePrefix(xs:string(fn:namespace-uri($i))))
      let $ns-prefix := if($ns-prefix-check) then $ns-prefix-check||":" else ("")
      let $localname := fn:local-name($i)
      let $rootname := fn:local-name(fn:root($i))
      let $finalpath := if($path) then fn:concat($path, "/", $ns-prefix, $localname)
                        else fn:concat($ns-prefix, $localname)
      return
        if($i/node()) then
          (if ($i/node() instance of text()) then fn:substring(fn:concat("/", $root-ns-prefix, $rootname, "/", $finalpath), 3)
           else (), local:get-children-nodes($finalpath, $i))
           else ()
      return fn:distinct-values($results)
};

declare function local:render-fields($doc as node(), $type as xs:string) {
    let $label := if ($type eq "query") then "Form Field:" else "Column Name:"
    let $input1 := if ($type eq "query") then "formLabel" else "columnName"
    let $input2 := if ($type eq "query") then "formLabelHidden" else "columnExpr"
    let $json-arr :=
      for $xpath at $p in local:get-children-nodes((), $doc)
      let $tokens := fn:tokenize($xpath, "/")
      let $xml :=
        <data>
          <label>{$label}</label>
          <xpath>{local:collapse-xpath($xpath)}</xpath>
          <xpathNormal>{fn:normalize-space(fn:tokenize($xpath, "--")[1])}</xpathNormal>
          <elementName>{$tokens[last()]}</elementName>
        </data>
      return to-json:xml-obj-to-json($xml)
    return to-json:seq-to-array-json($json-arr)
};

declare function local:collapse-xpath($xpath as xs:string){
  let $nodes := fn:tokenize($xpath, "/")
  let $nodescount := fn:count($nodes)
  let $new-xpath :=
    if ($nodescount eq 5) then
      fn:string-join(($nodes[2], $nodes[3], "...", $nodes[last()]), "/")
    else if ($nodescount eq 6) then
      fn:string-join(($nodes[2], $nodes[3], "...", "...", $nodes[last()]), "/")
    else $xpath
  return <span title="{$xpath}">{$new-xpath}</span>
};

try {
  if (check-user-lib:is-logged-in() and check-user-lib:is-wizard-user())
  then
    let $uploaded-doc := xdmp:unquote(xdmp:get-request-field("uploadedDoc"))
    let $_ := local:registerNamespaces($uploaded-doc)
    
    let $type := xdmp:get-request-field("type")
    
    let $type-label := if ($type eq "query") then "Query" else "View"
    let $query-view-name := if ($type eq "query") then "queryName" else "viewName"
    
    let $namespaces-map := $cfg:NS-MAP
    let $namespaces :=
      for $key in map:keys($namespaces-map)
      return
        to-json:xml-obj-to-json(<namespace><abbrv>{ map:get($namespaces-map, $key) }</abbrv><uri>{ $key }</uri></namespace>)
    
    let $fields := local:render-fields($uploaded-doc, $type)
   
    let $xml :=
      <data>
	      <type>{ $type-label }</type>
	      <possibleRoots>{
            to-json:seq-to-array-json(to-json:string-sequence-to-json(local:getStructure($uploaded-doc)))
          }</possibleRoots>
	      <rootElement>{fn:replace(xdmp:path($uploaded-doc/node()), "\[.*\]", "")}</rootElement>
	        {
	          let $prefix := cfg:getNamespacePrefix(xs:string(fn:namespace-uri($uploaded-doc/node())))
	          return 
	          	if ($prefix) then 
	          		<prefix>{ $prefix }</prefix> 
	          	else ()
	        }
	      <databases>{to-json:seq-to-array-json(to-json:string-sequence-to-json(lib-adhoc:get-databases()))}</databases>
	      <namespaces>{ to-json:seq-to-array-json($namespaces) }</namespaces>
	      <fields>{ $fields }</fields>
	  </data>
    let $_ := xdmp:log( "FROM: /server/endpoints/adhoc/wizard/api-adhoc-query-wizard.xqy", "debug")
    
    let $json := to-json:xml-obj-to-json($xml)
    return $json
  else
    xdmp:set-response-code(401, "User is not authorized.")
    
} catch ($e) {
  xdmp:log(
    ("Error processing uploaded sample doc...", xdmp:quote($e)), "notice"),
  xdmp:rethrow()
}