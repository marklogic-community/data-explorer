xquery version "1.0-ml";

module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";

declare  namespace sec="http://marklogic.com/xdmp/security";


declare variable $form-fields-map :=
	let $form-map := map:map()
	return $form-map
;

declare variable $data-types-map :=
let $dt-map := map:map()
return $dt-map
;

declare function lib-adhoc-create:get-elementname($file-type as xs:string,$xpath as xs:string, $position as xs:string){
  let $tokens := fn:tokenize($xpath, "/")
  let $elementname :=
    if ($position eq "last") then
      $tokens[fn:last()]
    else if($position eq "root") then
	    if ($file-type = $const:FILE_TYPE_XML) then
		  $tokens[1]
		else if ( $file-type = $const:FILE_TYPE_JSON) then
		  "/"
		else ()
	else
		()
  return $elementname
};

declare function lib-adhoc-create:create-params($i){
  fn:concat('let $param', $i, ' := map:get($params, "id', $i, '")')
};

declare function lib-adhoc-create:create-ewq($file-type as xs:string,$data-type as xs:string,$i, $xpath as xs:string) {
 let $elementname := lib-adhoc-create:get-elementname($file-type,$xpath, "last")
 return
	  if ( $file-type = $const:FILE_TYPE_XML) then
 			fn:concat('if ($param', $i, ') then cts:element-word-query(xs:QName("', $elementname, '"), $param', $i, ')
            else ()')
	  else   if ( $file-type = $const:FILE_TYPE_JSON) then
	      if ( $data-type = $const:DATA_TYPE_TEXT ) then
		    fn:concat('if ($param', $i, ') then cts:json-property-word-query("', $elementname, '", fn:string($param', $i, '))
               else ()')
		  else if ( $data-type = $const:DATA_TYPE_NUMBER ) then
			  fn:concat('if ($param', $i, ') then cts:json-property-value-query("', $elementname, '", xs:decimal($param', $i, '))
               else ()')
		  else if ( $data-type = $const:DATA_TYPE_BOOLEAN ) then
				  fn:concat('if ($param', $i, ') then cts:json-property-value-query("', $elementname, '", xs:boolean($param', $i, '))
               else ()')
		  else
				  ()
	  else
		  ()
};
declare function lib-adhoc-create:create-eq($file-type as xs:string,$xpath as xs:string, $params){
 let $elementname := lib-adhoc-create:get-elementname($file-type,$xpath, "root")
 return
	 if ( $file-type = $const:FILE_TYPE_XML ) then
		 fn:concat('cts:element-query(
  		    xs:QName("', $elementname, '"), cts:and-query((',  $params, ',if ($word) then
  			    cts:word-query($word, "case-insensitive")
 			   else
      		())))')
	 else if ( $file-type = $const:FILE_TYPE_JSON ) then
		 fn:concat('cts:and-query((',  $params, ',if ($word) then
  			    cts:json-property-word-query($word, "case-insensitive")
 			   else
      		()))')
	 else
		 ()

};

declare function lib-adhoc-create:file-name($query-name as xs:string)
	as xs:string
{
	let $str := fn:replace($query-name, " ", "_")
	let $str := fn:encode-for-uri($str)
	return $str || ".xml"
};

declare function lib-adhoc-create:create-edit-form-query($adhoc-fields as map:map)
	as document-node()
{
	let $prefix := map:get($adhoc-fields, "prefix")
	let $root-element := map:get($adhoc-fields, "rootElement")
	let $query-name := map:get($adhoc-fields, "queryName")
	let $querytext := map:get($adhoc-fields, "queryText")
	let $database := map:get($adhoc-fields, "database")
	let $file-type := map:get($adhoc-fields, "fileType")
	let $display-order := map:get($adhoc-fields, "displayOrder")
	return if (fn:not(fn:empty(//formQuery[queryName=$query-name and documentType=$root-element]))) then
					xdmp:unquote('{"status":"exists"}')
	else (
			let $uri :=
				(: For the filename, only use the local name of the last item in the XPath :)
				let $clean-element := fn:replace(fn:tokenize($root-element, "/")[fn:last()], "^.+?:", "")
				return fn:string-join(
						(
							"", "adhoc",
							if ($prefix) then $prefix else (),
							$clean-element,
							"forms-queries",
							lib-adhoc-create:file-name($query-name)
						), "/"
				)

			let $form-query :=
				<formQuery>
					<queryName>{$query-name}</queryName>
					<prefix>{$prefix}</prefix>
					<database>{$database}</database>
					<possibleRoots>
						{
							let $cnt := map:get($adhoc-fields, "possibleRootsCount")
							return if ( fn:empty($cnt)) then () else (
								for $i in (1 to xs:integer($cnt))
								let $pr := map:get($adhoc-fields, "possibleRoot" || $i)
								return <possibleRoot>{$pr}</possibleRoot>
							)
						}
					</possibleRoots>
					<namespaces>
						{
							let $cnt := map:get($adhoc-fields, "namespaceCount")
							return if ( fn:empty($cnt)) then () else (
								for $i in (1 to xs:integer($cnt))
								let $abbrv := map:get($adhoc-fields, "namespaceAbbrv" || $i)
								let $uri := map:get($adhoc-fields, "namespaceUri" || $i)
								return <namespace><abbr>{$abbrv}</abbr><uri>{$uri}</uri></namespace>
							)
						}
					</namespaces>
					{
						element documentType{
							if ($prefix) then
								attribute prefix{
									$prefix
								}
							else (),
							$root-element
						}
					}
					<formLabels>
					{
						let $counter := 1
						for $i in (1 to 250)
							let $dataType := map:get($adhoc-fields, fn:concat("formLabelDataType", $i))
							let $field-path := map:get($adhoc-fields, fn:concat("formLabelHidden", $i))
							return
								if (fn:exists($field-path)) then
									let $_ := map:put($form-fields-map, fn:concat("id", $counter), map:get($adhoc-fields, fn:concat("formLabelHidden", $i)))
									let $_ := map:put($data-types-map, fn:concat("id", $counter), map:get($adhoc-fields, fn:concat("formLabelDataType", $i)))
									let $_ := xdmp:set($counter, $counter + 1)
									return
										<formLabel id="{$i}" dataType="{$dataType}" evaluateAs="XPath"  expr="{$field-path}" exec_expr="{lib-adhoc:transform-xpath-with-spaces($field-path)}"/>
								else
									()
					}
					</formLabels>
					<searchFields>
						{
							let $counter := 1
							for $i in (1 to 250)
								let $label := map:get($adhoc-fields, fn:concat("formLabel", $i))
								let $mode := map:get($adhoc-fields, fn:concat("formLabelIncludeMode", $i))
								return
									if (fn:exists($label) and ($mode = "query" or $mode = "both"))  then
										<searchField id="{$i}" label="{$label}"/>
									else ()
						}
					</searchFields>
					<views>
						<view>
							  <name>DefaultView</name>
							  <displayOrder>{$display-order}</displayOrder>
							  <resultFields>
								  {
									  for $i in (1 to 250)
										  let $label := map:get($adhoc-fields, fn:concat("formLabel", $i))
										  let $mode := map:get($adhoc-fields, fn:concat("formLabelIncludeMode", $i))
										  return
											  if (fn:exists($label) and ($mode = "view" or $mode = "both"))  then
												  <resultField id="{$i}" label="{$label}"/>
											  else ()
								  }
							  </resultFields>
						</view>
					</views>
				  <code>{if($querytext) then $querytext else lib-adhoc-create:create-edit-form-code($file-type,$adhoc-fields)}</code>
				</formQuery>
		  let $_ := xu:document-insert($uri, $form-query)
		  return xdmp:unquote('{"status":"saved"}')
	  )
};

declare function lib-adhoc-create:create-edit-form-code($file-type as xs:string,$adhoc-fields as map:map){
	  let $params :=
	    for $key in map:keys($form-fields-map)
	    return lib-adhoc-create:create-params(fn:substring($key, 3))

	  let $word-query := fn:concat('let $word := map:get($params, "word")', fn:codepoints-to-string(10), 'return', fn:codepoints-to-string(10))
	  let $evqs :=
	    for $key in map:keys($form-fields-map)
    	return lib-adhoc-create:create-ewq($file-type,map:get($data-types-map,$key),fn:substring($key, 3),  map:get($form-fields-map, $key))
    return (
    	$params,
    	$word-query,
    	lib-adhoc-create:create-eq($file-type,
    		map:get($adhoc-fields, fn:concat("formLabelHidden", 1)),
    		fn:string-join($evqs, fn:concat(",", fn:codepoints-to-string(10)))
      )
    )
};