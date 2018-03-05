xquery version "1.0-ml";

module namespace sec-util = "http://marklogic.com/data-explore/lib/sec-utils";

import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
declare option xdmp:mapping "false";

declare function sec-util:get-role-names(
   $role-ids as xs:unsignedLong*
) as element(sec:role-name)* {

   sec:get-role-names($role-ids)
   
};




