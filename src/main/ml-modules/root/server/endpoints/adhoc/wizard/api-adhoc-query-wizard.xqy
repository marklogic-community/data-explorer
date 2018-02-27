xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace wl = "http://marklogic.com/data-explore/lib/wizard-lib" at "/server/lib/wizard-lib.xqy";
import module namespace nsl = "http://marklogic.com/data-explore/lib/namespaces-lib" at "/server/lib/namespaces-lib.xqy";


try {
  if (check-user-lib:is-logged-in() and check-user-lib:is-wizard-user())
  then
    let $uploaded-doc := xdmp:unquote(xdmp:get-request-field("uploadedDoc"))
    let $is-json := xdmp:get-request-field("mimeType") = "application/json"
    let $type := xdmp:get-request-field("type")
    
    let $profile := wl:profile-nodes($uploaded-doc)
    let $root-element := if ($is-json) then "/" else fn:replace(xdmp:path($uploaded-doc/node()), "\[.*\]", "")

    (: register any new namespaces :)
    let $_ := if ($profile/namespaces/@count gt 0) then nsl:register-namespaces($profile/namespaces/ns) else ()
  
    return wl:wizard-response($profile, $root-element, $type)
  else
    xdmp:set-response-code(401, "User is not authorized.")
    
} catch ($e) {
  xdmp:log(
    ("Error processing uploaded sample doc...", xdmp:quote($e)), "error"),
  xdmp:rethrow()
}