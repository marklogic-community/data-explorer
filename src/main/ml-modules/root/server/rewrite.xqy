xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";

import module namespace endpoints="http://example.com/ns/endpoints" at "/server/lib/endpoints.xqy";
import module namespace detail-lib = "http://www.marklogic.com/data-explore/lib/detail-lib" at "/server/lib/detail-lib.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $LOG_LEVEL := "debug";

declare option xdmp:mapping "false";

let $path := xdmp:get-request-path()

let $rewrite := rest:rewrite(endpoints:options())
let $_ := xdmp:log("FROM REWRITE : "||$path,"debug")
let $uri :=
  if( $path eq "/favicon.ico" ) then
    "/client/assets/images/favicon.ico"
  else if (empty($rewrite)) then
    fn:concat("/client",$path)
  else
    $rewrite

let $_ := xdmp:log(text{"REST controller: ", $path, " -> ", $uri} , $LOG_LEVEL)

return $uri