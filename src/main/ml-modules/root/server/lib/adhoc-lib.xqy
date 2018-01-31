xquery version "1.0-ml";

module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace riu = "http://marklogic.com/data-explore/lib/range-index-utils" at "/server/lib/range-index-utils.xqy";

declare namespace db = "http://marklogic.com/xdmp/database";



(:
    JSON can have properties with spaces. If you use this attributes with spaces in XPath
    it will not work ("//first//second with space//third"). So we need to transform such XPaths.
:)
declare function lib-adhoc:transform-xpath-with-spaces($xpath as xs:string) {
	fn:string-join(
			for $i in fn:tokenize($xpath,"/")
			return if (fn:contains($i,' ')) then
				fn:concat("*[name(.) = '",$i,"']")
			else
				$i
			,'/')
};

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

declare function lib-adhoc:get-query-form-items($doc-type as xs:string, $query as xs:string) as node()* {
	let $form-query-doc := cfg:get-form-query($doc-type, $query)
	let $database := $form-query-doc/database/fn:string()

	return for $option in $form-query-doc/formLabel
		let $form-field := fn:tokenize($option/@expr, "/")[fn:last()]
	  let $range-index := riu:get-index($database, $form-field)
	  return 
	  <formLabel>
	  { $option/* }
	  {
	  	if (fn:empty($range-index)) then () else (
	  		<rangeIndex>{ $form-field }</rangeIndex>,
	  		<scalarType>{ $range-index/db:scalar-type/fn:string() }</scalarType>
	  	)
	  }
		</formLabel>
};