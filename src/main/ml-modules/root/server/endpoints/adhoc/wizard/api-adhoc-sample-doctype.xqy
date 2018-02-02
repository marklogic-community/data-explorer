xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace wl = "http://marklogic.com/data-explore/lib/wizard-lib" at "/server/lib/wizard-lib.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 
import module namespace nsl = "http://marklogic.com/data-explore/lib/namespaces-lib" at "/server/lib/namespaces-lib.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";


declare private function local:map-namespace($ns-prefix as xs:string, $profile as node(), $ns-map as map:map) as xs:string* {
  let $act-ns := $profile/namespaces/ns[@prefix eq $ns-prefix]
  return map:get($ns-map, $act-ns)
};

declare private function local:render-path-token($token as node(), $profile as node()) as xs:string* {
  let $ns := local:map-namespace($token/@prefix, $profile, $cfg:NS-MAP)
  return fn:string-join(($ns, $token), ":")
};

declare private function local:render-path-element($path as node(), $profile as node()) as xs:string* {
  let $ns := local:map-namespace($path/@prefix, $profile, $cfg:NS-MAP)
  return fn:string-join(($ns, $path/@name), ":")
};

declare private function local:response($profile as node(), $root-element as xs:string, $type as xs:string) as node()* {
  let $response := json:object()
  let $type-label := if ($type eq "query") then "Query" else "View"
  let $field-label := if ($type eq "query") then "Form Field:" else "Column Name:"
  let $has-json-nodes := $profile/paths/path/@type = "object"
  let $possible-roots := (if ($has-json-nodes) then "/" else (), $profile/paths/path/@path-no-ns ! fn:concat("/", .))
  let $mapped-ns := $profile/namespaces/ns ! object-node { 
    "abbrv": map:get($cfg:NS-MAP, .),
    "uri": fn:string(.)
  }
  let $root-mapped-ns := local:map-namespace($profile/paths/path[fn:concat("/", @path-no-ns) eq $root-element]/@prefix, $profile, $cfg:NS-MAP)
  
  let $fields := for $path in $profile/paths/path[@type = ("text", "boolean", "number", "null", "element")]
    let $mapped-tokens := $path/token ! local:render-path-token(., $profile)
    let $xpath := fn:concat(if ($has-json-nodes) then "/" else (), fn:string-join($mapped-tokens, "/"))
    return object-node {
      "label": $field-label,
      "dataType": fn:string(if ($path/@type eq "element") then "text" else $path/@type),
      "xpath": fn:string(wl:collapse-xpath($has-json-nodes, $xpath)),
      "xpathNormal": $xpath,
      "elementName": local:render-path-element($path, $profile)
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

declare function local:process() {
  let $payload := xdmp:get-request-body()
  let $database := $payload/database
  let $ns := $payload/ns
  let $root-name := $payload/name
  let $type := $payload/type

  let $eval-expr := if ($root-name eq "/") then "/" else fn:concat(if (fn:string-length($ns) le 0) then '' else 'qn:', $root-name)
  let $max-samples := 100
  let $eval := fn:concat(
    if (fn:string-length($ns) le 0) then '' else 'declare namespace qn ="' || $ns || '"; ',
    'cts:search(/' || $eval-expr || ', (), ("unfiltered", "score-random"))[1 to ' || $max-samples || ']'
  )
  let $nodes-to-sample := xu:eval(
    $eval, 
    (), 
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($database) }</database>
    </options>)

  let $profile := wl:profile-nodes($nodes-to-sample)
  let $root-element := fn:concat("/", if (fn:string-length($ns) le 0) then () else "*:", $root-name) 

  (: register any new namespaces :)
  let $_ := if ($profile/namespaces/@count gt 0) then nsl:register-namespaces($profile/namespaces/ns) else ()
  
  return local:response($profile, $root-element, $type)
};


if (check-user-lib:is-logged-in() and check-user-lib:is-wizard-user()) 
then local:process()
else xdmp:set-response-code(401, "User is not authorized.")
