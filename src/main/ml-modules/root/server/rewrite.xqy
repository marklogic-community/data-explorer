xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";

import module namespace endpoints="http://example.com/ns/endpoints" at "/server/lib/endpoints.xqy";
import module namespace detail-lib = "http://www.marklogic.com/data-explore/lib/detail-lib" at "/server/lib/detail-lib.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $path := xdmp:get-request-path()

let $rewrite := rest:rewrite(endpoints:options())
let $_ := ll:trace("FROM REWRITE : "||$path)
let $uri :=
  if( $path eq "/favicon.ico" ) then
    "/client/assets/images/favicon.ico"
  (: 
   : This rewrite assumes that any path without a "." in it is an application route)
   : and directs to our index.html
   :)
  else if( fn:not(fn:contains($path, ".")) and empty($rewrite) ) then
    "/client/index.html"
  else if (empty($rewrite)) then
    fn:concat("/client",$path)
  else
    $rewrite

let $_ := ll:trace(text{"REST controller: ", $path, " -> ", $uri} )

return $uri