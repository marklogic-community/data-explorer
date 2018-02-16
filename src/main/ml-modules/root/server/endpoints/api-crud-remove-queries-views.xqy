xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";

declare function local:remove-queries-views() {
    let $name := map:get($cfg:getRequestFieldsMap, "name")
    let $mode := map:get($cfg:getRequestFieldsMap, "mode")
    let $_ := if ( fn:empty($name) or $name = '' ) then fn:error(xs:QName("ERROR"),"Name may not be empty.") else ()
    let $_ := if ( $mode != 'Queries' and $mode != 'Views' ) then fn:error(xs:QName("ERROR")," $mode="||$mode||" should be 'Queries' or 'Views") else ()
    let $docs := if ( $mode = 'Views' ) then /view[viewName=$name] else /formQuery[queryName=$name]
    let $_ := $docs ! xdmp:document-delete(fn:base-uri(.))
    return ()
};

if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (local:remove-queries-views())
else (xdmp:set-response-code(401, "User is not authorized."))
