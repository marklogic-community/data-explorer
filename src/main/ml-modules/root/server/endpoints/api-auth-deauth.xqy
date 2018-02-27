xquery version "1.0-ml";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";

let $_ := ll:trace("FROM: /server/endpoints/api-auth-deauth.xqy")
return
(
xdmp:logout(),
xdmp:set-response-code(200, "logged out")
)