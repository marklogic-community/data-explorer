xquery version "1.0-ml";

module namespace wl = "http://marklogic.com/data-explore/lib/wizard-lib";


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