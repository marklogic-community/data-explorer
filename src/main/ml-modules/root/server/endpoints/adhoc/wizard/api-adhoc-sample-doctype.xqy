xquery version "1.0-ml";

import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace wl = "http://marklogic.com/data-explore/lib/wizard-lib" at "/server/lib/wizard-lib.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 
import module namespace nsl = "http://marklogic.com/data-explore/lib/namespaces-lib" at "/server/lib/namespaces-lib.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";


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
  
  return wl:wizard-response($profile, $root-element, $type)
};


if (check-user-lib:is-logged-in() and check-user-lib:is-wizard-user()) 
then local:process()
else xdmp:set-response-code(401, "User is not authorized.")
