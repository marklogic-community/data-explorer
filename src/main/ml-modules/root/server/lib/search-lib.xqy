xquery version "1.0-ml";

module namespace search-lib = "http://marklogic.com/data-explore/lib/search-lib";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace detail-lib = "http://www.marklogic.com/data-explore/lib/detail-lib"
  at "/server/lib/detail-lib.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" 
      at "/MarkLogic/admin.xqy";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 


declare namespace db="http://marklogic.com/xdmp/database";
declare option xdmp:mapping "false";

declare function search-lib:page-count($sr as element())
{
  fn:ceiling(xs:int($sr/@total) div xs:int($sr/@page-length))
};

declare function search-lib:result-count($sr as element()){
  xs:int($sr/@total)
};

declare function search-lib:index-exists($index as xs:string,$namespace as xs:string, $db as xs:string)
{
  let $config := admin:get-configuration()
  return try {fn:exists(admin:database-get-range-element-indexes($config, xdmp:database($db) )[./fn:tokenize(db:localname/text()," ")=$index and ./db:namespace-uri/text()=$namespace])}
        catch($exception){fn:false()}
  
};

declare function search-lib:inDir(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query)) 
as schema-element(cts:query)
{
  let $query :=
  <root>{
    let $dir := fn:string($right//cts:text/text())
    return
        cts:directory-query($dir,"infinity")
      }
  </root>/*
  return
  (: add qtextconst attribute so that search:unparse will work - 
     required for some search library functions :)
  element { fn:node-name($query) }
    { attribute qtextconst { 
        fn:concat($constraint-qtext, fn:string($right//cts:text)) },
      $query/@*,
      $query/node()} 
};

declare function search-lib:search($params as map:map, $useDB as xs:string,$export as xs:boolean?){
  let $searchText := fn:concat("",map:get($params, "searchText"))
  let $searchFacet :=  map:get($params, "selectedfacet")
  let $additional-query := map:get($params, "additionalquery")
  let $page := xs:int(map:get($params, "pagenumber"))
  let $page := if ($page) then xs:int($page) else (1)
  let $page-size:=if(fn:exists($export) and $export) then $cfg:max-export-records else $cfg:pagesize
  let $db := map:get($params, "database")
  let $doc-type := map:get($params, "docType")
  let $query-name := map:get($params, "queryName")
  let $view-name := map:get($params, "viewName")

  let $final-search := ($searchText, $searchFacet)

  let $view :=
    if (fn:exists($view-name)) then
      cfg:get-view($doc-type, $view-name)
    else
      ()

  (: Get the order to display the columns in. Could be 
   : alphabetical or document-order. If not stored in view,
   : default to document-order :)
  let $display-order := 
    if(fn:exists($view/displayOrder)) then
      $view/displayOrder/text()
    else "document-order"

  let $log :=
    if ($cfg:D) then
      (
        xdmp:log(text{ "db: ", $db }),
        xdmp:log(text{ "doc-type: ", $doc-type }),
        xdmp:log(text{ "view-name: ", $view-name }),
        xdmp:log(text{ "view: ", xdmp:describe($view, (), ()) })
      )
    else
      ()

  let $options :=

    <options xmlns="http://marklogic.com/appservices/search">
      <additional-query>
      {
        $additional-query
      }
      </additional-query>
      <return-results>true</return-results>
      <return-facets>true</return-facets>
      <return-query>true</return-query>
      <search-option>unfiltered</search-option>
      <transform-results apply="snippet" xmlns="http://marklogic.com/appservices/search">
        <per-match-tokens>30</per-match-tokens>
        <max-matches>3</max-matches>
        <max-snippet-chars>200</max-snippet-chars>
      </transform-results>
      <term apply="term">
        <empty apply="all-results"/>
      </term>
      <constraint name="inDir">
        <custom facet="false">
          <parse apply="inDir" ns="http://marklogic.com/data-explore/lib/search-lib" at="/server/lib/search-lib.xqy"/>
        </custom>
      </constraint>
      <grammar>
        <quotation>"</quotation>
        <implicit>
          <cts:and-query strength="20" xmlns:cts="http://marklogic.com/cts"/>
        </implicit>
        <starter strength="30" apply="grouping" delimiter=")">(</starter>
        <starter strength="40" apply="prefix" element="cts:not-query">-</starter>
        <joiner strength="10" apply="infix" element="cts:or-query" tokenize="word">OR</joiner>
        <joiner strength="20" apply="infix" element="cts:and-query" tokenize="word">AND</joiner>
        <joiner strength="30" apply="infix" element="cts:near-query" tokenize="word">NEAR</joiner>
        <joiner strength="30" apply="near2" consume="2" element="cts:near-query">NEAR/</joiner>
        <joiner strength="32" apply="boost" element="cts:boost-query" tokenize="word">BOOST</joiner>
        <joiner strength="35" apply="not-in" element="cts:not-in-query" tokenize="word">NOT_IN</joiner>
        <joiner strength="50" apply="constraint">:</joiner>
        <joiner strength="50" apply="constraint" compare="LT" tokenize="word">LT</joiner>
        <joiner strength="50" apply="constraint" compare="LE" tokenize="word">LE</joiner>
        <joiner strength="50" apply="constraint" compare="GT" tokenize="word">GT</joiner>
        <joiner strength="50" apply="constraint" compare="GE" tokenize="word">GE</joiner>
        <joiner strength="50" apply="constraint" compare="NE" tokenize="word">NE</joiner>
      </grammar>
      {
        map:get($params, "facets")
      }
      {
        if ($doc-type = ()) then
          ()
        else if (search-lib:index-exists("lastModified", "http://test", $db)) then
          <constraint name="modifiedDate">
            <range type="xs:dateTime">
              <element ns="http://test" name="lastModified"/>
              <computed-bucket name="0Future" ge="PT0S" anchor="now">Future</computed-bucket>
              <computed-bucket name="10Min10" ge="-PT10M" lt="PT0S" anchor="now">Last 10 Min</computed-bucket>
              <computed-bucket name="15Min30" ge="-PT30M" lt="PT0S" anchor="now">Last Half Hour</computed-bucket>
              <computed-bucket name="17Min60" ge="-PT1H" lt="PT0S" anchor="now">Last Hour</computed-bucket>
              <computed-bucket name="21week" ge="-P6D" lt="PT0S" anchor="start-of-day">Last 7 Days</computed-bucket>
              <computed-bucket name="30today" ge="P0D" lt="P1D" anchor="start-of-day">Today</computed-bucket>
              <computed-bucket name="35yesterday" ge="-P1D" lt="-P0D" anchor="start-of-day">Yesterday</computed-bucket>
              <computed-bucket name="40thismonth" ge="P0M" lt="P1M" anchor="start-of-month">This Month</computed-bucket>
              <computed-bucket name="45month" ge="-P1M" lt="P0M" anchor="start-of-month">Last Month</computed-bucket>
              <computed-bucket name="60thisyear" ge="P0Y" lt="P1Y" anchor="start-of-year">This Year</computed-bucket>
              <computed-bucket name="65year" ge="-P1Y" lt="P0Y" anchor="start-of-year">Last Year</computed-bucket>
              <computed-bucket name="68older" lt="-P1Y" anchor="start-of-year">Before Last Year</computed-bucket>
            </range>
          </constraint>
        else
          ()
      }
    </options>

  let $search-response := search-lib:get-results($useDB, $final-search, $options, $page, $page-size)

  return
    (: { result-count:4, current-page:4, page-count:10, results:[]}:)
    if ($search-response//search:result) then
      let $results :=
        for $result in $search-response/search:result
          return search-lib:result-to-view($result,$view,$useDB)
      return
        <output>
          <result-count>{search-lib:result-count($search-response)}</result-count>
          <current-page>{$page}</current-page>
          <page-count>{search-lib:page-count($search-response)}</page-count>
          <display-order>{$display-order}</display-order>
          <result-headers><header>URI</header>{for $c in $view/columns/column return <header>{$c/@name/string()}</header>}</result-headers>
          <results>{$results}</results>
        </output>
    else
      <output>
        <result-count>0</result-count>
      </output>
  };

  declare function search-lib:result-to-view($result as element(),$view as element(), $useDB as xs:string){
    let $uri := $result/fn:data(@uri)
    let $doc := detail-lib:get-document($uri,$useDB)
    let $view-xqy := fn:concat($cfg:namespaces,
        "
        
        declare variable $view external;
        declare variable $doc external;

        for $column in $view/columns/column
        let $expr := $column/fn:string(@expr)
        let $name := xs:string($column/@name)
        let $expr :=
          if( fn:contains($expr, '$') ) then
            $expr
          else
            fn:concat('$doc/', $expr)
        let $values := xdmp:value(fn:string($expr)) ! fn:normalize-space(.)
        return
          <part><name>{fn:normalize-space($name)}</name>{$values ! <value>{fn:string(.)}</value>}</part>")
    let $view-parts := xu:eval(
      $view-xqy,
      ((xs:QName("view"),$view),(xs:QName("doc"),$doc))
    )

    return
      <result>
      {
        <part><name>URI</name><value><a href='/detail/{$useDB}/{$uri}'>{$uri}</a></value></part>
        ,
        $view-parts
      }
      </result>
  };

  declare function search-lib:make-element($name,$value){
    element {$name} { ($value) }
  };


  declare function search-lib:get-results($db,$search as xs:string+,$options as element(search:options)?,$page,$page-size){
    xu:eval(
    'xquery version "1.0-ml";
    import module namespace search = "http://marklogic.com/appservices/search"
      at "/MarkLogic/appservices/search/search.xqy";
    declare variable $searchQuoted external;
    declare variable $options as element(search:options)? external;
    declare variable $page external;
    declare variable $page-size external;
    let $search as xs:string+ := 
      if (fn:string-length($searchQuoted) > 0) then
        fn:tokenize($searchQuoted,"<join>")
      else
        ""
    return search:search(
      $search,
      $options,
      (($page - 1) * $page-size) + 1,
      $page-size
    )',
  ((xs:QName("searchQuoted"),fn:string-join($search,"<join>")),(xs:QName("options"),$options),(xs:QName("page"),$page),
    (xs:QName("page-size"),$page-size)),
  <options xmlns="xdmp:eval">
    <database>{xdmp:database($db)}</database>
  </options>)
};