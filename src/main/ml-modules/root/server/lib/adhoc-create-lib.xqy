xquery version "1.0-ml";

module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "/MarkLogic/appservices/utils/in-mem-update.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace nl = "http://marklogic.com/data-explore/lib/namespace-lib"  at "/server/lib/namespace-lib.xqy";

declare  namespace sec="http://marklogic.com/xdmp/security";


declare private variable $form-fields-map :=
	let $form-map := map:map()
	return $form-map
;

declare private variable $data-types-map :=
let $dt-map := map:map()
return $dt-map
;

declare function lib-adhoc-create:create-discriminator-query($database as xs:string,$namespaces as element(),$file-type as xs:string,$doc-type as xs:string) {
	let $qry := cts:true-query()
	let $tokens := fn:reverse(fn:tokenize($doc-type,"/"))
	let $_ := for $token in $tokens
	return if (fn:string-length($token) > 0) then (
		let $level-query := if ( $file-type = $const:FILE_TYPE_XML) then
			cts:element-query(nl:get-qname($database,$namespaces,$token),$qry)
		else
			cts:json-property-scope-query($token,$qry)
		return xdmp:set($qry,$level-query)
	) else
		()
	return $qry
};

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
	let $tokens := fn:filter(function($item) { fn:string-length($item) > 0 }, fn:tokenize($xpath,'/'))
	let $count := fn:count($tokens)
	let $qryFunction := if ( $file-type = $const:FILE_TYPE_XML) then
							"cts:element-query"
	                    else
							"cts:json-property-scope-query"
	let $elQueries :=
		for $el in $tokens[1 to -1+$count]
           let $name := if ( $file-type = $const:FILE_TYPE_XML) then
		                       fn:concat('xs:QName("',$el,'")')
		                else
		                       fn:concat('"',$el,'"')
		   return fn:concat($qryFunction,"(",$name,",")
		let $closing := functx:repeat-string(")",fn:count($elQueries))
	let $latest-query := lib-adhoc-create:create-ewq-lastest($file-type,$data-type,$i,$xpath)
	return fn:concat('if ($param', $i, ') then ',fn:string-join($elQueries,""),$latest-query,$closing,'else ()')
};

declare function lib-adhoc-create:create-ewq-lastest($file-type as xs:string,$data-type as xs:string,$i, $xpath as xs:string) {
 let $elementname := lib-adhoc-create:get-elementname($file-type,$xpath, "last")
 return
	  if ( $file-type = $const:FILE_TYPE_XML) then
 			      fn:concat('cts:element-word-query(xs:QName("', $elementname, '"), $param', $i, ')')
	  else   if ( $file-type = $const:FILE_TYPE_JSON) then
	      if ( $data-type = $const:DATA_TYPE_TEXT ) then
		          fn:concat('cts:json-property-word-query("', $elementname, '", fn:string($param', $i, '))')
		  else if ( $data-type = $const:DATA_TYPE_NUMBER ) then
				  fn:concat('cts:json-property-value-query("', $elementname, '", xs:decimal($param', $i, '))')
		  else if ( $data-type = $const:DATA_TYPE_BOOLEAN ) then
				  fn:concat('cts:json-property-value-query("', $elementname, '", xs:boolean($param', $i, '))')
		  else
				  ()
	  else
		  ()
};
declare function lib-adhoc-create:create-eq($database as xs:string,$namespaces as element(),$file-type as xs:string,$root-element as xs:string,$xpath as xs:string, $params){
 let $elementname := lib-adhoc-create:get-elementname($file-type,$xpath, "root")
 return
	 if ( $file-type = $const:FILE_TYPE_XML ) then
		 fn:concat('cts:and-query((',lib-adhoc-create:create-discriminator-query($database,$namespaces,$file-type,$root-element), ',', $params, ',if ($word) then
  			    cts:word-query($word, "case-insensitive")
 			   else
      		()))')
	 else if ( $file-type = $const:FILE_TYPE_JSON ) then
		 fn:concat('cts:and-query((',lib-adhoc-create:create-discriminator-query($database,$namespaces,$file-type,$root-element),',' , $params, ',if ($word) then
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
	let $overwrite := map:get($adhoc-fields, "overwrite") = "OVERWRITE"
	let $root-element := map:get($adhoc-fields, "rootElement")
	let $query-name := map:get($adhoc-fields, "queryName")
	let $querytext := map:get($adhoc-fields, "queryText")
	let $bookmark-label := map:get($adhoc-fields,"bookmarkLabel")
	let $view-name :=  map:get($adhoc-fields, "viewName")
	let $view-name := if (fn:empty($view-name)) then $const:DEFAULT-VIEW-NAME else $view-name
	let $database := map:get($adhoc-fields, "database")
	let $file-type := map:get($adhoc-fields, "fileType")
	let $display-order := map:get($adhoc-fields, "displayOrder")
	return if (fn:not($overwrite) and fn:not(fn:empty(//formQuery[@version=$const:SUPPORTED-VERSION and queryName=$query-name and documentType=$root-element]))) then
					xdmp:unquote('{"status":"exists"}')
	else (
			let $uri :=
				let $clean-element := fn:replace($root-element, ":", "")
				return fn:string-join(
						(
							"", "adhoc"||$clean-element,
							"forms-queries",
							lib-adhoc-create:file-name($query-name)
						), "/"
				)
            let $add-view := <view>
				<name>{$view-name}</name>
			    <bookmarkLabel>{$bookmark-label}</bookmarkLabel>
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
			let $existing-views := fn:doc($uri)//views

			let $new :=  if ( fn:empty($existing-views)) then
							<views>{$add-view}</views>
							else if ( $add-view/name/fn:string() = $existing-views/view/name/fn:string() ) then
								let $node := $existing-views/view[name=$add-view/name/fn:string()]
								return mem:node-replace($node,$add-view)//views
							else
								let $node := $existing-views
								return mem:node-insert-child($node,$add-view)//views
			let $namespaces := <namespaces>
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
			let $form-query :=
				<formQuery version="{$const:SUPPORTED-VERSION}">
					<queryName>{$query-name}</queryName>
					<database>{$database}</database>
				    <fileType>{$file-type}</fileType>
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
					{$namespaces}
					<documentType>{$root-element}</documentType>
					<formLabels>
					{
						for $i in (1 to 250)
							let $dataType := map:get($adhoc-fields, fn:concat("formLabelDataType", $i))
							let $field-path := map:get($adhoc-fields, fn:concat("formLabelHidden", $i))
							return
								if (fn:exists($field-path)) then
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
										let $_ := map:put($form-fields-map, fn:concat("id", $counter), map:get($adhoc-fields, fn:concat("formLabelHidden", $i)))
										let $_ := map:put($data-types-map, fn:concat("id", $counter), map:get($adhoc-fields, fn:concat("formLabelDataType", $i)))
										let $_ := xdmp:set($counter, $counter + 1)
										return
											<searchField id="{$i}" label="{$label}"/>
									else ()
						}
					</searchFields>
					{$new}
				  <code>{if($querytext) then $querytext else lib-adhoc-create:create-edit-form-code($database,$namespaces,$file-type,$adhoc-fields,$root-element)}</code>
				</formQuery>
		  let $_ := xu:document-insert($uri, $form-query)
		  return xdmp:unquote('{"status":"saved"}')
	  )
};

declare function lib-adhoc-create:create-edit-form-code($database,$namespaces as element(),$file-type as xs:string,$adhoc-fields as map:map,$root-element as xs:string){
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
    	lib-adhoc-create:create-eq($database,$namespaces,$file-type,$root-element,
    		map:get($adhoc-fields, fn:concat("formLabelHidden", 1)),
    		fn:string-join($evqs, fn:concat(",", fn:codepoints-to-string(10)))
      )
    )
};