xquery version "1.0-ml";

let $_ := xdmp:log("FROM: /server/endpoints/api-auth-deauth.xqy","debug")
return
(
xdmp:logout(),
xdmp:set-response-code(200, "logged out")
)