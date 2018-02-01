xquery version "1.0-ml";

module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib";

import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 

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

declare function lib-adhoc:get-query-form-items($docType as xs:string, $query as xs:string) as node()* {
	cfg:get-form-query($docType, $query)//formLabel
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
