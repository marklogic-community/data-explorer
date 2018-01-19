xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const"
at "/server/lib/const.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;


declare function local:get-structure($is-json as xs:boolean,$doc) {
  if ( $is-json ) then
      ("/",local:get-children-nodes-json(fn:true(),(),$doc/node())/path/fn:string())
  else (
      for $d in $doc/child::*
        return (xdmp:path($d), local:get-structure($is-json,$d)) ! fn:replace(., "\[.*\]", "")
  )
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

declare function local:get-children-nodes-xml($path, $node as node()) {
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
          (if ($i/node() instance of text()) then
               <child><path>{fn:substring(fn:concat("/", $root-ns-prefix, $rootname, "/", $finalpath), 3)}</path><dataType>text</dataType></child>
           else (), local:get-children-nodes-xml($finalpath, $i))
           else ()
      return functx:distinct-deep($results)
};

declare function local:get-children-nodes-json($get-structure as xs:boolean,$path,$node as node()) {
    let $results :=
        for $i in $node/node()
        let $localname := fn:name($i)
        let $finalpath := fn:concat($path, "/", $localname)
        return
            if ($i instance of null-node()) then
                    ()
            else if ($i instance of text() or
                    $i instance of  number-node() or
                    $i instance of boolean-node() or
                    ($i instance of null-node() )) then
                <child><path>{$finalpath}</path><dataType>{xdmp:node-kind(xdmp:unpath($finalpath,(),fn:root($i)))[1]}</dataType></child>
            else if ($i instance of object-node() ) then
                (
                   local:get-children-nodes-json ($get-structure,$finalpath, $i),
                   if ($get-structure) then
                    <child><path>{$finalpath}</path><dataType>object</dataType></child>
                   else ()
                )
            else if ($i instance of array-node()) then
                    local:get-children-nodes-json ($get-structure,$path,$i)
                else
                    ()
    return functx:distinct-deep($results)
};

declare function local:render-fields($doc as node(), $type as xs:string,$is-json as xs:boolean) {
    let $label := if ($type eq "query") then "Form Field:" else "Column Name:"
    let $children := if ( $is-json ) then
                        local:get-children-nodes-json(fn:false(),(),$doc/node())
                    else
                        local:get-children-nodes-xml((),$doc)
    let $json-arr :=
      for $child in $children
        let $xpath := $child/path/fn:string()
        let $tokens := fn:tokenize($xpath, "/")
        let $xml :=
            <data>
                <label>{$label}</label>
                <dataType>{$child/dataType/fn:string()}</dataType>
                <xpath>{local:collapse-xpath($is-json,$xpath)}</xpath>
                <xpathNormal>{fn:normalize-space(fn:tokenize($xpath, "--")[1])}</xpathNormal>
            <elementName>{$tokens[last()]}</elementName>
            </data>
        return to-json:xml-obj-to-json($xml)
    return to-json:seq-to-array-json($json-arr)
};

declare function local:collapse-xpath($is-json as xs:boolean,$xpath as xs:string){
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
    let $is-json := xdmp:get-request-field("mimeType") = "application/json"

    let $type := xdmp:get-request-field("type")
    
    let $type-label := if ($type eq "query") then "Query" else "View"
    let $query-view-name := if ($type eq "query") then "queryName" else "viewName"

    let $_ := if ( $is-json = fn:false() ) then ( local:registerNamespaces($uploaded-doc) ) else ()
    let $namespaces-map := $cfg:NS-MAP
    let $namespaces :=
       if ( $is-json = fn:false() ) then (
        for $key in map:keys($namespaces-map)
           return
             to-json:xml-obj-to-json(<namespace><abbrv>{ map:get($namespaces-map, $key) }</abbrv><uri>{ $key }</uri></namespace>)
        ) else ()

    let $fields := local:render-fields($uploaded-doc, $type,$is-json)
   
    let $xml :=
      <data>
	      <type>{ $type-label }</type>
	      <possibleRoots>{
            to-json:seq-to-array-json(to-json:string-sequence-to-json(local:get-structure($is-json,$uploaded-doc)))
          }</possibleRoots>
	      <rootElement>{if ($is-json) then "/" else fn:replace(xdmp:path($uploaded-doc/node()), "\[.*\]", "")}</rootElement>
	        {
	          let $prefix := if($is-json) then () else cfg:getNamespacePrefix(xs:string(fn:namespace-uri($uploaded-doc/node())))
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
    let $_ := xdmp:log($json,"debug")
    return $json
  else
    xdmp:set-response-code(401, "User is not authorized.")
    
} catch ($e) {
  xdmp:log(
    ("Error processing uploaded sample doc...", xdmp:quote($e)), "error"),
  xdmp:rethrow()
}