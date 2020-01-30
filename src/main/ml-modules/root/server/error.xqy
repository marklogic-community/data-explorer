xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib"  at "/server/lib/check-user-lib.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace error = "http://marklogic.com/xdmp/error";
declare option xdmp:mapping "false";
declare variable $error:errors as node()* external;

let $config := json:config("custom")
let $_ := map:put($config, "array-element-names", (xs:QName("error:error"), xs:QName("error:stack"),xs:QName("error:frame"), xs:QName("error:variable")))
return (
    xdmp:set-response-content-type("application/json"),
    json:transform-to-json($error:errors, $config)
)