xquery version "1.0-ml";

module namespace cfg = "http://www.marklogic.com/data-explore/lib/config";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 


(: START OF PROPERTIES YOU CAN MODIFY :)
declare variable $cfg:app-title := "Data-Explorer";

declare variable $cfg:search-role := "data-explorer-search-role";
declare variable $cfg:wizard-role := "data-explorer-wizard-role";

declare variable $cfg:access-priv:="http://marklogic.com/ps/data-explorer-access";

declare variable $cfg:create-user := fn:false();

declare variable $cfg:tokenize := ",";
declare variable $cfg:pagesize := 10;
declare variable $cfg:max-export-records := 1000;

(: does some debug logging when true :)
declare variable $D := fn:true();

declare variable $cfg:NS-IGNORE-LIST := ("http://www.w3.org/XML/1998/namespace");

declare variable $cfg:NS-SERVER-FIELD := "namespaces-conf";
declare variable $cfg:NS-URI := "/adhoc/namespaces.xml";
declare variable $cfg:NS-DOC as document-node()? := fn:doc($NS-URI);
declare variable $cfg:NS-MAP :=
      let $cached-map := xu:get-server-field($cfg:NS-SERVER-FIELD)
      return
        if (fn:exists($cached-map)) then
          $cached-map
        else
          let $db-or-empty-map :=
            if ($NS-DOC)
            then (map:map($NS-DOC/namespaces/map:map))
            else (map:map())
          let $CACHE := xu:set-server-field($cfg:NS-SERVER-FIELD, $db-or-empty-map)
          return $db-or-empty-map
;



(: END OF PROPERTIES YOU CAN MODIFY :)

declare variable $cfg:getRequestFieldsMap :=
  let $map := map:map()
  let $_ :=
    for $field in xdmp:get-request-field-names()
    return
     if (xdmp:get-request-field($field)) then
     (
       if ( $cfg:D ) then
          xdmp:log(fn:concat("RequestField '",$field,"' = '",xdmp:get-request-field($field),"'"))
       else
          ()
       ,
       map:put($map, $field, xdmp:get-request-field($field))
     )
     else
        ()
  return $map
;

declare variable $cfg:namespaces :=
  let $ns-map := $cfg:NS-MAP
  let $text :=
    for $ns-uri in map:keys($ns-map)
    return fn:concat('declare namespace ',map:get($ns-map, $ns-uri),'="',$ns-uri,'";')
  return fn:string-join($text)
;

declare variable $ignoreDbs :=
  ("App-Services", "Documents", "Extensions", "Fab", "Last-Login", "Schemas", "Security","Meters");

declare variable $defaultDb := "FFE";

declare variable $PROLOG := 
  fn:concat('
    import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
      at "/server/lib/config.xqy";
    import module namespace search = "http://marklogic.com/appservices/search"
      at "/MarkLogic/appservices/search/search.xqy";',
      $cfg:namespaces,
      '
    declare option xdmp:transaction-mode "query";
    declare variable $params as map:map external;
  ')
;

(: returns all of the localnames of the document types that have form-query objects :)
declare function cfg:get-document-types($db as xs:string) as xs:string*
{
  let $names :=
    let $form-queries :=
      cfg:search-config("formQuery", cts:element-value-query(xs:QName("database"), $db))
    for $fq in $form-queries
    return $fq/fn:string(documentType)

  let $names := fn:distinct-values($names)

  for $name in $names
  order by $name
  return $name
};

declare function cfg:getNamespacePrefix($uri as xs:string?) as xs:string?
{
  xs:string(map:get($cfg:NS-MAP,$uri))
};

declare function cfg:getNamespaceUri($prefix as xs:string?) as xs:string?
{
  for $key in map:keys($cfg:NS-MAP)
  let $val := map:get($cfg:NS-MAP,$key)
  return if($val = $prefix) then $key  else()
};

declare function cfg:get-query-names($document-type as xs:string, $database as xs:string)
  as xs:string*
{
  let $names :=
    let $form-queries :=
      cfg:search-config("formQuery",
    cts:and-query((
            cts:element-value-query(xs:QName("documentType"), $document-type),
            cts:element-value-query(xs:QName("database"), $database)
    ))
      )
    for $fq in $form-queries
    return $fq/fn:string(queryName)

  let $names := fn:distinct-values($names)

  for $name in $names
  order by $name
  return $name
};

declare function cfg:get-form-query(
  $document-type as xs:string,
  $query-name as xs:string)
  as element(formQuery)?
{
  cfg:search-config("formQuery",
    cts:and-query((
      cts:element-value-query(xs:QName("documentType"), $document-type),
      cts:element-value-query(xs:QName("queryName"), $query-name)
    ))
  )
};

declare function cfg:get-view-names($document-type as xs:string, $database as xs:string)
  as xs:string*
{
  let $names :=
    let $views :=
      cfg:search-config("view",
    cts:and-query((
            cts:element-value-query(xs:QName("documentType"), $document-type),
            cts:element-value-query(xs:QName("database"), $database)
    ))
      )
    for $view in $views
    return $view/fn:string(viewName)

  let $names := fn:distinct-values($names)

  for $name in $names
  order by $name
  return $name
};

declare function cfg:get-view(
  $document-type as xs:string,
  $view-name as xs:string)
  as element(view)?
{
  cfg:search-config("view",
    cts:and-query((
      cts:element-value-query(xs:QName("documentType"), $document-type),
      cts:element-value-query(xs:QName("viewName"), $view-name)
    ))
  )
};


declare function cfg:search-config($source as xs:string, $query as cts:query)
{
  xu:value(fn:concat("cts:search(/", $source, ",", $query, ")"))
};

declare function cfg:delete-document($uri as xs:string) {
  xdmp:document-delete($uri)
};