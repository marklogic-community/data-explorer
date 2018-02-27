xquery version "1.0-ml";

module namespace wl = "http://marklogic.com/data-explore/lib/wizard-lib";

import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";


(: moved from api-adhoc-query-wizard.xqy :)
declare function wl:collapse-xpath($is-json as xs:boolean,$xpath as xs:string){
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

(: used by profile-nodes to keep track of encountered namespaces :)
declare private function wl:resolve-namespace-prefix($namespace as xs:string, $namespaces as map:map) as xs:string*
{
  if (fn:string-length($namespace) le 0) then ()
  else
    if (map:contains($namespaces, $namespace))
    then map:get($namespaces, $namespace)
    else
      let $prefix := "_" || map:count($namespaces) + 1
      return (map:put($namespaces, $namespace, $prefix), $prefix)
};

(: returns a summary of namespaces and paths given a sequence of nodes :)
declare function wl:profile-nodes($roots as node()*) as node()
{
  let $namespaces := json:object(), $paths := json:object() (: json:object retains insert sequence :)
  let $_ := for $root in $roots
    for $node in $root/descendant-or-self::* 
    let $root-to-node := $node/ancestor-or-self::*
    let $path-tokens := for $n in $root-to-node
      let $qname := fn:node-name($n)
      let $prefix := wl:resolve-namespace-prefix(fn:namespace-uri-from-QName($qname), $namespaces)
      return element token { 
        if ($prefix) then attribute prefix { $prefix } else (),
        fn:local-name-from-QName($qname)
      }
    let $path-ns := fn:string-join($path-tokens ! fn:string-join((./@prefix, .), ":") , "/")
    let $path-no-ns := fn:string-join($path-tokens ! fn:concat(if (./@prefix) then "*:" else (), .), "/")
    let $last-token := $path-tokens[fn:last()]
    let $node-path := element path {
      attribute name { $last-token },
      $last-token/@prefix,
      attribute path-no-ns { $path-no-ns },
      attribute path-ns { $path-ns },
      attribute type { xdmp:node-kind($node) },
      $path-tokens
    }
    return if (map:contains($paths, $path-ns)) then () else map:put($paths, $path-ns, $node-path)
          
  return element profile {
    element namespaces {
      attribute count { map:count($namespaces) },
      map:keys($namespaces) ! element ns {
        attribute prefix { map:get($namespaces, .) }, 
        .
      }
    },
    element paths {
      map:keys($paths) ! map:get($paths, .)
    },
    element metrics {
      element elapsed-time { xdmp:elapsed-time() }
    }
  }
};

declare function wl:roots-from-profile($profile as node(), $include-slash-root as xs:boolean) as xs:string*
{
  (
    if ($include-slash-root) then "/" else (), 
    $profile/paths/path/@path-no-ns ! fn:concat("/", .)
  )
};

declare private function wl:map-namespace($ns-prefix as xs:string, $profile as node(), $ns-map as map:map) as xs:string* {
  let $act-ns := $profile/namespaces/ns[@prefix eq $ns-prefix]
  return map:get($ns-map, $act-ns)
};

declare private function wl:render-path-token($token as node(), $profile as node()) as xs:string* {
  let $ns := wl:map-namespace($token/@prefix, $profile, $cfg:NS-MAP)
  return fn:string-join(($ns, $token), ":")
};

declare private function wl:render-path-element($path as node(), $profile as node()) as xs:string* {
  let $ns := wl:map-namespace($path/@prefix, $profile, $cfg:NS-MAP)
  return fn:string-join(($ns, $path/@name), ":")
};

declare function wl:wizard-response($profile as node(), $root-element as xs:string, $type as xs:string) as node()* {
  let $response := json:object()
  let $type-label := if ($type eq "query") then "Query" else "View"
  let $field-label := if ($type eq "query") then "Form Field:" else "Column Name:"
  let $has-json-nodes := $profile/paths/path/@type = "object" or $root-element eq "/"
  let $possible-roots := wl:roots-from-profile($profile, $has-json-nodes)
  let $mapped-ns := $profile/namespaces/ns ! object-node { 
    "abbrv": map:get($cfg:NS-MAP, .),
    "uri": fn:string(.)
  }
  let $root-mapped-ns := wl:map-namespace($profile/paths/path[fn:concat("/", @path-no-ns) eq $root-element]/@prefix, $profile, $cfg:NS-MAP)
  
  let $fields := for $path in $profile/paths/path[@type = ("text", "boolean", "number", "null", "element")]
    let $mapped-tokens := $path/token ! wl:render-path-token(., $profile)
    let $xpath := fn:concat(if ($has-json-nodes) then "/" else (), fn:string-join($mapped-tokens, "/"))
    return object-node {
      "label": $field-label,
      "dataType": fn:string(if ($path/@type eq "element") then "text" else $path/@type),
      "xpath": fn:string(wl:collapse-xpath($has-json-nodes, $xpath)),
      "xpathNormal": $xpath,
      "elementName": wl:render-path-element($path, $profile)
    }
  
  return (
    map:put($response, "type", $type-label),
    map:put($response, "possibleRoots", json:to-array($possible-roots)),
    map:put($response, "rootElement", $root-element),
    if ($root-mapped-ns) then map:put($response, "prefix", $root-mapped-ns) else (),
    map:put($response, "databases", json:to-array(lib-adhoc:get-databases())),
    map:put($response, "namespaces", json:to-array($mapped-ns)),
    map:put($response, "fields", json:to-array($fields)),
    xdmp:to-json($response)
  )
};