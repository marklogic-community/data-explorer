xquery version "1.0-ml";

module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" ;

import module namespace sec = "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
import module namespace sec-util = "http://marklogic.com/data-explore/lib/sec-utils" at "/server/lib/sec-utils.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";

declare function check-user-lib:is-admin() {
    let $security-database := admin:database-get-security-database(admin:get-configuration(), xdmp:database())

    return
        xdmp:invoke-function(
                function() {
                    try {
                        let $_ := sec:check-admin()
                        return fn:true()
                    } catch ($exception) {
                        fn:false()
                    }
                },
                <options xmlns="xdmp:eval">
                    <database>{$security-database}</database>
                </options>)
};

declare function check-user-lib:is-wizard-user() as xs:boolean
{
    let $user-roles := check-user-lib:get-roles()
    return
    ($user-roles = $cfg:wizard-role) or check-user-lib:is-admin()
};

declare function check-user-lib:is-search-user() as xs:boolean {
    let $user-roles := check-user-lib:get-roles()
    return
    ($user-roles = $cfg:search-role) or check-user-lib:is-admin()
};

(: This function is used only in reset password - api-users-pass.xqy - can be removed if reset password is not an option :)
declare function check-user-lib:is-user($user-id as xs:string) as xs:boolean {
    (check-user-lib:is-wizard-user()) or ($user-id = xdmp:get-current-user())
};

declare function check-user-lib:is-logged-in(){
    xdmp:has-privilege($cfg:access-priv,"execute")
};

declare function check-user-lib:get-roles(){
  xu:invoke-function(
    function() { sec-util:get-role-names( xdmp:get-current-roles() )  },
    <options xmlns="xdmp:eval">
      <database>{xdmp:security-database()}</database>
    </options>
  )
};

