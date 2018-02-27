xquery version "1.0-ml";

import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://marklogic.com/data-explore/lib/check-database-lib" at "/server/lib/check-database-lib.xqy" ;
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";


declare function local:update-password(){
    cd:check-database(),
    let $user-id := xdmp:get-current-user()
    let $password := xdmp:get-request-field("newpassword")  
    let $password2 := xdmp:get-request-field("newpasswordconfirm")
    
    return
    if(check-user-lib:is-user($user-id)) then
        if (local:isPasswordsMatch($password, $password2))
        then 
            try {
                let $_ :=
                    xu:eval('
                        import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
                        let $user-id := "admin"
                        let $password := "admin"
                        return sec:user-set-password($user-id,$password)
                           ',(),
                            <options xmlns="xdmp:eval">
                                <database>{xdmp:database("Security")}</database>
                            </options>
                    )
               return xdmp:set-response-code(200, 'Successfully Changed Password')
           } catch ($e) {
                (ll:trace($e),
                xdmp:set-response-code(500,'Password Update Failed'))
           }
        else (
            xdmp:set-response-code(400, fn:concat('Passwords do not match:',$password,":",$password2,"#"))
        )
    else
        xdmp:set-response-code(401,'Cant edit other users')
};  

(: add check for current password:)

declare function local:isPasswordsMatch($password, $password2) as xs:boolean {

    ($password)
    and
    ($password2)
    and
    ($password = $password2)

};

let $_ := ll:trace("FROM: /server/endpoints/api-users-pass.xqy")
return
local:update-password()


