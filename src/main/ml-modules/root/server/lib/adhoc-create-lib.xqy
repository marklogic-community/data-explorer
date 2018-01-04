xquery version "1.0-ml";

module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"at "/server/lib/config.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 


declare  namespace sec="http://marklogic.com/xdmp/security";


declare variable $form-fields-map :=
	let $form-map := map:map()
	return $form-map
;

declare function lib-adhoc-create:get-elementname($xpath as xs:string, $position as xs:string){
  let $tokens := fn:tokenize($xpath, "/")
  let $elementname :=
    if ($position eq "last") then
      $tokens[fn:last()]
    else if($position eq "root") then $tokens[1] else $tokens[2]
  return $elementname
};

declare function lib-adhoc-create:create-params($i){
  fn:concat('let $param', $i, ' := map:get($params, "id', $i, '")')
};

declare function lib-adhoc-create:create-evq($i, $xpath as xs:string){
 let $elementname := lib-adhoc-create:get-elementname($xpath, "last")
 return
 fn:concat('if ($param', $i, ') then cts:element-value-query(xs:QName("', $elementname, '"), $param', $i, ')
            else ()')
};
declare function lib-adhoc-create:create-ewq($i, $xpath as xs:string){
 let $elementname := lib-adhoc-create:get-elementname($xpath, "last")
 return
 fn:concat('if ($param', $i, ') then cts:element-word-query(xs:QName("', $elementname, '"), $param', $i, ')
            else ()')
};
declare function lib-adhoc-create:create-eq($xpath as xs:string, $params){
 let $elementname := lib-adhoc-create:get-elementname($xpath, "root")
 return
 fn:concat('cts:element-query(
      xs:QName("', $elementname, '"), cts:and-query((',  $params, ',if ($word) then
      cts:word-query($word, "case-insensitive")
    else
      ())))')
};

declare function lib-adhoc-create:file-name($query-name as xs:string)
	as xs:string
{
	let $str := fn:replace($query-name, " ", "_")
	let $str := fn:encode-for-uri($str)
	return $str || ".xml"
};

declare function lib-adhoc-create:create-edit-form-query($adhoc-fields as map:map)
	as xs:boolean
{
	let $prefix := map:get($adhoc-fields, "prefix")
	let $root-element := map:get($adhoc-fields, "rootElement")
	let $query-name := map:get($adhoc-fields, "queryName")
	let $querytext := map:get($adhoc-fields, "queryText")
	let $database := map:get($adhoc-fields, "database")


	let $uri :=
		(: For the filename, only use the local name of the last item in the XPath :)
		let $clean-element := fn:replace( fn:tokenize($root-element, "/")[fn:last()], "^.+?:", "")
		return fn:string-join(
			(
				"", "adhoc", 
				if($prefix) then $prefix else(""), 
				$clean-element, 
				"forms-queries", 
				lib-adhoc-create:file-name($query-name)
			), "/"
		)

	let $form-query :=
		<formQuery>
		  <queryName>{ $query-name }</queryName>
		  <database>{$database}</database>
			{
				element documentType{
					if($prefix) then
						attribute prefix{
							$prefix
						}
					else(),
					$root-element
				}
			}
		  {
		  	let $counter := 1
		  	for $i in (1 to 250)
		  	let $label := map:get($adhoc-fields, fn:concat("formLabel", $i))
		  	let $mode := map:get($adhoc-fields, fn:concat("formLabelIncludeMode", $i))
		  	return
		  		if (fn:exists($label) and ($mode eq "both" or $mode eq "query")) then
		  		  let $_ := map:put($form-fields-map, fn:concat("id", $counter), map:get($adhoc-fields, fn:concat("formLabelHidden", $i)))
		  		  let $_ := xdmp:set($counter, $counter + 1)
		  		  return
		  			<formLabel>{ $label }</formLabel>
		  		else
		  			()
		  }
		  <code>{if($querytext) then $querytext else lib-adhoc-create:create-edit-form-code($adhoc-fields)}</code>
		</formQuery>
  let $_ := xu:document-insert($uri, $form-query)

	return fn:true()
};

declare function lib-adhoc-create:create-edit-form-code($adhoc-fields as map:map){
	  let $params :=
	    for $key in map:keys($form-fields-map)
	    return lib-adhoc-create:create-params(fn:substring($key, 3))

	  let $word-query := fn:concat('let $word := map:get($params, "word")', fn:codepoints-to-string(10), 'return', fn:codepoints-to-string(10))
	  let $evqs :=
	    for $key in map:keys($form-fields-map)
    	return lib-adhoc-create:create-ewq(fn:substring($key, 3),  map:get($form-fields-map, $key))
    return (
    	$params,
    	$word-query,
    	lib-adhoc-create:create-eq(
    		map:get($adhoc-fields, fn:concat("formLabelHidden", 1)),
    		fn:string-join($evqs, fn:concat(",", fn:codepoints-to-string(10)))
      )
    )
};

declare function lib-adhoc-create:create-edit-view($adhoc-fields as map:map)
	as empty-sequence()
{
	let $prefix := map:get($adhoc-fields, "prefix")
	let $root-element := map:get($adhoc-fields, "rootElement")
	let $view-name := map:get($adhoc-fields, "viewName")
	let $database := map:get($adhoc-fields, "database")
	return
		if ($root-element and $view-name) then
			let $uri :=
				(: For the filename, only use the local name of the last item in the XPath :)
				let $clean-element := fn:replace( fn:tokenize($root-element, "/")[fn:last()], "^.+?:", "")
				return fn:string-join(
					(
						"", "adhoc", 
						if($prefix) then $prefix else(""), 
						$clean-element, 
						"views", 
						lib-adhoc-create:file-name($view-name)
					), "/"
				)

			let $view :=
				<view>
				  <viewName>{ $view-name }</viewName>
				  <database>{$database}</database>
				  {
					element documentType{
						if($prefix) then
							attribute prefix{
								$prefix
							}
						else(),
						$root-element
					}
				  }
				  <columns>
				  {
				  	for $i in (1 to 15)
				  	let $name := map:get($adhoc-fields, "columnName" || $i)
				  	let $expr := map:get($adhoc-fields, "columnExpr" || $i)
				  	let $mode := map:get($adhoc-fields, "columnIncludeMode" || $i)
				  	return
				  		if (fn:exists($name) and fn:exists($expr) and ($mode eq "both" or $mode eq "view")) then
				  			<column name="{ $name }" evaluateAs="XPath" expr="{ $expr }" />
				  		else
				  			()
				  }
					</columns>
				</view>

		  return xu:document-insert($uri, $view)

		else
			fn:error((), fn:concat(("A required param is missing"," prefix",$prefix," rootElement",$root-element, " viewName",$view-name," database",$database)))
};

declare function lib-adhoc-create:check-view-exists($adhoc-fields as map:map) as xs:boolean{
	let $prefix := map:get($adhoc-fields, "prefix")
	let $root-element := map:get($adhoc-fields, "rootElement")
	let $query-name := map:get($adhoc-fields, "queryName")
	let $querytext := map:get($adhoc-fields, "queryText")
	let $database := map:get($adhoc-fields, "database")
	return
	xu:eval(
		'
		declare variable $query-name external;
		declare variable $root-element external;
		declare variable $prefix external;

		xdmp:estimate(
			cts:search(fn:doc()/view,
		      cts:and-query((
		        cts:element-value-query(xs:QName("viewName"),$query-name||"-Default-View"),
		        cts:element-value-query(xs:QName("documentType"),$root-element),
		        cts:element-attribute-value-query(xs:QName("documentType"), xs:QName("prefix"),$prefix)
		      ))
		    )
		)
		'
		,
		(
			xs:QName("query-name"), $query-name,
			xs:QName("root-element"), $root-element,
			xs:QName("prefix"),($prefix,"")[1]
		)
		,
		<options xmlns="xdmp:eval">
		  <database>{xdmp:database($database)}</database>
		</options>
	) ge 1

};