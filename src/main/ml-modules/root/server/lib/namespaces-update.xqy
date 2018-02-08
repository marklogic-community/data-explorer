xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 

(: moved from api-adhoc-query-wizard.xqy :)
declare variable $namespaces as xs:string* external;

let $reserved-ns := ("http://www.w3.org/XML/1998/namespace")

let $existing-map := $cfg:NS-MAP
let $pref-map := map:map()
let $_ := for $key in map:keys($existing-map) 
  let $onlytext := fn:tokenize(map:get($existing-map, $key), "\d+")[1] 
  return if (map:get($pref-map,$onlytext)) 
  then map:put($pref-map, $onlytext, map:get($pref-map,$onlytext) + 1)
  else map:put($pref-map, $onlytext, 1)

let $new-map := map:map()
let $_ := for $ns in $namespaces where $ns != $reserved-ns
  return if(fn:string-length($ns) ge 1 and fn:not($ns eq $cfg:NS-IGNORE-LIST)) then (
    let $ns-prefix := fn:string-join((
        for $word in tokenize($ns, '\W+')[. != '']
        return codepoints-to-string(string-to-codepoints($word)[1])
      )
      ,"")

    let $ns-prefix := if(map:get($pref-map, $ns-prefix)) then (
        $ns-prefix||map:get($pref-map, $ns-prefix),
        map:put($pref-map, $ns-prefix, map:get($pref-map, $ns-prefix) + 1)
      )
      else (
        $ns-prefix,
        map:put($pref-map, $ns-prefix, 1)
      )
    
    return if(fn:not(map:get($existing-map, $ns)))
    then map:put($new-map, $ns, $ns-prefix)
    else ()
  )
  else ()

return if(map:count($new-map) ge 1) 
then (
  let $all-map := if (map:count($existing-map) ge 1)
  then ($existing-map + $new-map)
  else ($new-map)
  let $doc := element namespaces { $all-map }
  return (
    xu:document-insert($cfg:NS-URI,$doc),
    xdmp:set-server-field($cfg:NS-SERVER-FIELD, $all-map)
    )
)
else ()