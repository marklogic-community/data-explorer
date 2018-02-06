xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;


let $_ := xdmp:log("START: /server/endpoints/adhoc/wizard/api-adhoc-query-wizard-create.xqy","debug")
let $create-form := map:get($cfg:getRequestFieldsMap, "queryText")
let $display-order := map:get($cfg:getRequestFieldsMap, "displayOrder")
let $_ := 
	if(map:contains($cfg:getRequestFieldsMap, "queryName")) then 
		let $_ := lib-adhoc-create:create-edit-form-query($cfg:getRequestFieldsMap)
		return 
			if(fn:not(lib-adhoc-create:check-view-exists($cfg:getRequestFieldsMap))) then
			(
				let $defaultViewMap := map:map()
				let $_ := map:put($defaultViewMap, "viewName", map:get($cfg:getRequestFieldsMap,"queryName")||"-Default-View")
				let $_ := 
					for $key in map:keys($cfg:getRequestFieldsMap)
					return 
					if(fn:matches($key,"formLabelHidden[0-9]")) then
						map:put($defaultViewMap, "columnExpr"||fn:tokenize($key,"[A-z]")[fn:last()], map:get($cfg:getRequestFieldsMap, $key))
					else if(fn:matches($key, "formLabelIncludeMode[0-9]")) then
						map:put($defaultViewMap, "columnIncludeMode"||fn:tokenize($key,"[A-z]")[fn:last()], map:get($cfg:getRequestFieldsMap, $key))
					else if (fn:matches($key,"formLabel[0-9]")) then
						map:put($defaultViewMap, "columnName"||fn:tokenize($key,"[A-z]")[fn:last()], map:get($cfg:getRequestFieldsMap, $key))
					else(map:put($defaultViewMap, $key, map:get($cfg:getRequestFieldsMap, $key)))
				return lib-adhoc-create:create-edit-view($defaultViewMap, $display-order) 
			)
			else()
  	else lib-adhoc-create:create-edit-view($cfg:getRequestFieldsMap, $display-order)
let $message :=
    <div>
      <p>Created new query: { map:get($cfg:getRequestFieldsMap, "queryName") }</p>
      <div><a href="/adhoc">Return to Search</a></div>
    </div>
let $_ := xdmp:log("FROM: /server/endpoints/adhoc/wizard/api-adhoc-query-wizard-create.xqy","debug")

return $message