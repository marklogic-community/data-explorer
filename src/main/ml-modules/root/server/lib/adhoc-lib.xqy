xquery version "1.0-ml";

module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace riu = "http://marklogic.com/data-explore/lib/range-index-utils" at "/server/lib/range-index-utils.xqy";

declare namespace db = "http://marklogic.com/xdmp/database";


declare function lib-adhoc:get-databases() as xs:string*{
	for $db in fn:distinct-values(
				for $server in xdmp:servers()
				return try { xdmp:database-name(xdmp:server-database($server)) } catch($e) {()}
			   )
  	where fn:not($db = ($cfg:ignoreDbs))
  	order by $db ascending
    return $db
};

declare function lib-adhoc:get-doctypes($database as xs:string) as xs:string*{

	let $log := if ($cfg:D) then xdmp:log(text{ "database ", $database }) else ()
	let $names := cfg:get-document-types($database)
	let $log := if ($cfg:D) then xdmp:log(text{ "get-doctypes ", fn:string-join($names, ",") }) else ()
	return
	  $names
};

declare function lib-adhoc:get-query-names($database as xs:string, $docType as xs:string) as xs:string*{
	let $log := if ($cfg:D) then xdmp:log(text{ "get-query-names docType := [ ", $docType, "]    $database :=  [",$database,"]" }) else ()

	let $names := cfg:get-query-names($docType,$database)
	let $log := if ($cfg:D) then xdmp:log(text{ "get-query-names ", fn:string-join($names, ",") }) else ()
	return $names
};

declare function lib-adhoc:get-view-names($database as xs:string, $docType as xs:string) as xs:string*{
	let $log := if ($cfg:D) then xdmp:log(text{ "get-view-names docType := [ ", $docType, "]    $database :=  [",$database,"]" }) else ()

	let $names := cfg:get-view-names($docType,$database)
	let $log := if ($cfg:D) then xdmp:log(text{ "get-view-names ", fn:string-join($names, ",") }) else ()
	return $names
};

declare function lib-adhoc:get-query-form-items($doc-type as xs:string, $query as xs:string) as json:array {
	let $form-query-doc := cfg:get-form-query($doc-type, $query)
	let $database := $form-query-doc/database/fn:string()

	let $form-options := for $option in $form-query-doc/formLabel
		let $form-field := fn:tokenize($option/@expr, "/")[fn:last()]
	  let $range-index := riu:get-index($database, $form-field)
	  let $json := json:object()
	  return (
	  	map:put($json, "label", $option/fn:string()),
	  	if (fn:empty($range-index)) then () else (
	  		map:put($json, "rangeIndex", $form-field), (: this will be used to query for index values :)
	  		map:put($json, "scalarType", $range-index/db:scalar-type/fn:string())
	  	),
	  	$json
	  )

	return json:to-array($form-options)
};