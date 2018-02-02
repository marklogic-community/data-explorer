xquery version "1.0-ml";

module namespace nsl = "http://marklogic.com/data-explore/lib/namespaces-lib";

import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 


(: moved from api-adhoc-query-wizard.xqy :)
declare function nsl:register-namespaces($namespaces as xs:string*) {
  xu:invoke(
    "/server/lib/namespaces-update.xqy",
    map:entry(xdmp:key-from-QName(xs:QName("namespaces")), $namespaces),
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
      <prevent-deadlocks>true</prevent-deadlocks>
    </options>)
};