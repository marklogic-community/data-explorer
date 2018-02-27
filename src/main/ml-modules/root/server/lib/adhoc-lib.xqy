xquery version "1.0-ml";

module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib";

import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace riu = "http://marklogic.com/data-explore/lib/range-index-utils" at "/server/lib/range-index-utils.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";

declare namespace db = "http://marklogic.com/xdmp/database";
declare namespace qry = "http://marklogic.com/cts/query";

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
				return try { xdmp:database-name(xdmp:server-database($server)) } catch($e) {ll:trace($e)}
			   )
  	where fn:not($db = ($cfg:ignoreDbs))
  	order by $db ascending
    return $db
};

declare function lib-adhoc:get-doctypes($database as xs:string) as xs:string*{
	let $_ := ll:trace(text{ "database ", $database })
	let $names := cfg:get-document-types($database)
	let $_ := ll:trace(text{ "get-doctypes ", fn:string-join($names, ",") })
	return
	  $names
};

declare function lib-adhoc:get-query-names($database as xs:string, $docType as xs:string) as xs:string*{
	let $_ := ll:trace(text{ "get-query-names docType := [ ", $docType, "]    $database :=  [",$database,"]" })
	let $names := cfg:get-query-names($docType,$database)
	let $_ := ll:trace(text{ "get-query-names ", fn:string-join($names, ",") })
	return $names
};

declare function lib-adhoc:get-view-names($database as xs:string, $docType as xs:string) as xs:string*{
	let $_ := ll:trace(text{ "get-view-names docType := [ ", $docType, "]    $database :=  [",$database,"]" })
	let $names := cfg:get-view-names($docType,$database)
	let $_ := ll:trace(text{ "get-view-names ", fn:string-join($names, ",") })
	return $names
};

declare function lib-adhoc:get-query-form-items($form-query-doc as element(formQuery)) as node()* {
  let $database := $form-query-doc/database/fn:string()

  return for $option in $form-query-doc/searchFields/searchField
    let $dict := $form-query-doc/formLabels/formLabel[@id=$option/@id]
    let $form-field := fn:tokenize($dict/@expr, "/")[fn:last()]
    let $range-index := riu:get-index($database, $form-field)
    let $dataType := fn:string($dict/@dataType)
    let $label := fn:string($option/@label)
    return 
    <formLabel>
        <dataType>{$dataType}</dataType>
        <label>{$label}</label>
    {
      if (fn:empty($range-index)) then () else (
        <rangeIndex>{ $form-field }</rangeIndex>,
        <scalarType>{ $range-index/db:scalar-type/fn:string() }</scalarType>
      )
    }
    </formLabel>
};

declare private function lib-adhoc:term-from-root-qname($qname as xs:QName)
as xs:unsignedLong
{
  let $ns := fn:string(fn:namespace-uri-from-QName($qname))
  let $eval := fn:concat(
    if (fn:string-length($ns) le 0) then '' else 'declare namespace qn ="' || $ns || '"; ',
    'xdmp:plan(/',
    if (fn:string-length($ns) le 0) then '' else 'qn:',
    fn:local-name-from-QName($qname),
    ')'
  )
  return xu:eval($eval, ())//qry:term-query[fn:starts-with(qry:annotation, "doc-root")]/qry:key/data()
};

declare private function lib-adhoc:next-root-qname($query as cts:query?, $except-terms as xs:unsignedLong*)
as xs:QName*
{
  let $full-query := cts:and-query((
    $query,
    $except-terms ! cts:not-query(cts:term-query(., 0))
  ))
  let $next := fn:head(cts:search(/*, $full-query))
  let $next-qname := fn:node-name($next)
  let $next-term := lib-adhoc:term-from-root-qname($next-qname)
  return (
    $next-qname,
    if (fn:empty($next-qname)) then () else lib-adhoc:next-root-qname($query, ($except-terms, $next-term))
  )
};

declare function lib-adhoc:get-root-qnames($database as xs:string)
as xs:QName*
{
	xu:invoke-function(function() {
      lib-adhoc:next-root-qname((), ())
    },
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($database) }</database>
    </options>
  )
};
