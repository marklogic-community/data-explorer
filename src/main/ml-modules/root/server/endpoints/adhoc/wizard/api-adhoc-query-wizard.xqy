xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace wl = "http://marklogic.com/data-explore/lib/wizard-lib" at "/server/lib/wizard-lib.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";
import module namespace nl = "http://marklogic.com/data-explore/lib/namespace-lib"  at "/server/lib/namespace-lib.xqy";


declare function local:get-structure($is-json as xs:boolean,$doc) {
  if ( $is-json ) then
      ("/",local:get-children-nodes-json(fn:true(),(),$doc/node())/path/fn:string())
  else (
      for $d in $doc/child::*
        return ("/"||nl:get-path($d), local:get-structure($is-json,$d)) ! fn:replace(., "\[.*\]", "")
  )
};

declare function local:get-children-nodes-xml($path, $node as node()) {
  let $results :=
      for $i in $node/node()
      let $root-ns-prefix := nl:get-prefix(fn:root($i))
      let $root-ns-prefix := if (fn:string-length(fn:normalize-space($root-ns-prefix)) > 0) then $root-ns-prefix||":" else()
      let $ns-prefix := nl:get-prefix($i)
      let $ns-prefix := if (fn:string-length(fn:normalize-space($ns-prefix)) > 0) then $ns-prefix||":" else()
      let $localname := fn:local-name($i)
      let $rootname := fn:local-name(fn:root($i))
      let $s := fn:concat($ns-prefix, $localname)
      let $finalpath := if($path) then
                            fn:concat($path, "/",$s)
                        else
                            $s
      return
        if($i/node()) then
          (if ($i/node() instance of text()) then
               <child><path>{fn:concat( "/", $finalpath)}</path><dataType>text</dataType></child>
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
                <child><path>{$finalpath}</path><dataType>{xdmp:node-kind($i)}</dataType></child>
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
                <xpath>{wl:collapse-xpath($is-json,$xpath)}</xpath>
                <xpathNormal>{fn:normalize-space(fn:tokenize($xpath, "--")[1])}</xpathNormal>
            <elementName>{$tokens[last()]}</elementName>
            </data>
        return to-json:xml-obj-to-json($xml)
    return to-json:seq-to-array-json($json-arr)
};

try {
  if (check-user-lib:is-logged-in() and check-user-lib:is-wizard-user())
  then
    let $uploaded-doc := xdmp:unquote(xdmp:get-request-field("uploadedDoc"))
    let $is-json := xdmp:get-request-field("mimeType") = "application/json"

    let $type := xdmp:get-request-field("type")
    
    let $type-label := if ($type eq "query") then "Query" else "View"
    let $namespaces-map := nl:get-prefix-namespace-map($uploaded-doc)
    let $namespaces :=
       if ( $is-json = fn:false() ) then (
        for $key in map:keys($namespaces-map)
           return
             to-json:xml-obj-to-json(<namespace><abbrv>{ $key }</abbrv><uri>{map:get($namespaces-map, $key)}</uri></namespace>)
        ) else ()

    let $fields := local:render-fields($uploaded-doc, $type,$is-json)
   
    let $xml :=
      <data>
	      <type>{ $type-label }</type>
	      <possibleRoots>{
            to-json:seq-to-array-json(to-json:string-sequence-to-json(local:get-structure($is-json,$uploaded-doc)))
          }</possibleRoots>
	      <rootElement>{if ($is-json) then "/" else fn:replace(xdmp:path($uploaded-doc/node()), "\[.*\]", "")}</rootElement>
	      <databases>{to-json:seq-to-array-json(to-json:string-sequence-to-json(lib-adhoc:get-databases()))}</databases>
	      <namespaces>{ to-json:seq-to-array-json($namespaces) }</namespaces>
	      <fields>{ $fields }</fields>
	  </data>
    let $_ := ll:trace( "FROM: /server/endpoints/adhoc/wizard/api-adhoc-query-wizard.xqy")
    
    let $json := to-json:xml-obj-to-json($xml)
    let $_ := ll:trace(("Returning JSON ",$json))
    return $json
  else
    xdmp:set-response-code(401, "User is not authorized.")
    
} catch ($e) {
  ll:trace(
    ("Error processing uploaded sample doc...", xdmp:quote($e))),
  xdmp:rethrow()
}