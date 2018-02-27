xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";


let $_ := ll:trace("START: /server/endpoints/adhoc/wizard/api-adhoc-query-wizard-create.xqy")
let $ret :=
	if(map:contains($cfg:getRequestFieldsMap, "queryName") and map:contains($cfg:getRequestFieldsMap, "rootElement")) then
		lib-adhoc-create:create-edit-form-query($cfg:getRequestFieldsMap)
	else
        xdmp:unquote('{"status":"dataError"}')
let $_ := ll:trace("FROM: /server/endpoints/adhoc/wizard/api-adhoc-query-wizard-create.xqy")
return $ret