xquery version "1.0-ml";

module namespace cfg = "http://www.marklogic.com/data-explore/lib/config";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
import module namespace ll = "http://marklogic.com/data-explore/lib/logging-lib"  at "/server/lib/logging-lib.xqy";
import module namespace nl = "http://marklogic.com/data-explore/lib/namespace-lib"  at "/server/lib/namespace-lib.xqy";

(: START OF PROPERTIES YOU CAN MODIFY :)
declare variable $cfg:app-title := "Data-Explorer";

declare variable $cfg:search-role := "data-explorer-search-role";
declare variable $cfg:wizard-role := "data-explorer-wizard-role";

declare variable $cfg:access-priv:="http://marklogic.com/ps/data-explorer-access";

declare variable $cfg:create-user := fn:false();

declare variable $cfg:tokenize := ",";
declare variable $cfg:pagesize := 10;
declare variable $cfg:max-export-records := 1000;


(: END OF PROPERTIES YOU CAN MODIFY :)

declare variable $cfg:getRequestFieldsMap :=
  let $map := map:map()
  let $_ :=
    for $field in xdmp:get-request-field-names()
    return
     if (xdmp:get-request-field($field)) then
     (
       ll:trace(fn:concat("RequestField '",$field,"' = '",xdmp:get-request-field($field),"'"))
       ,
       map:put($map, $field, xdmp:get-request-field($field))
     )
     else
        ()
  return $map
;

declare variable $ignoreDbs :=
  ("App-Services", "Documents", "Extensions", "Fab", "Last-Login", "Schemas", "Security","Meters");

declare variable $defaultDb := "FFE";

declare function cfg:get-prolog($query as xs:string,$doc-type as xs:string) {
  let $_ := ll:trace(("GET PROLOG",$query,$doc-type))
  return fn:concat('
    import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
      at "/server/lib/config.xqy";
    import module namespace search = "http://marklogic.com/appservices/search"
      at "/MarkLogic/appservices/search/search.xqy";',
          nl:get-namespace-declaration($query,$doc-type),
          '
    declare option xdmp:transaction-mode "query";
    declare variable $params as map:map external;
  ')
};

(: returns all of the localnames of the document types that have form-query objects :)
declare function cfg:get-document-types($db as xs:string) as xs:string*
{
  let $names := fn:distinct-values(/formQuery[@version=$const:SUPPORTED-VERSION and database=$db]/documentType/fn:string())
  for $name in $names
  order by $name
  return $name
};

declare function cfg:get-query-names($document-type as xs:string, $database as xs:string)
  as xs:string*
{
  let $names := fn:distinct-values(/formQuery[@version=$const:SUPPORTED-VERSION and documentType=$document-type and database=$database]/queryName/fn:string())
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
  /formQuery[@version=$const:SUPPORTED-VERSION and documentType=$document-type and queryName=$query-name]
};

declare function cfg:get-view-names($document-type as xs:string, $database as xs:string)
  as xs:string*
{
  let $names := fn:distinct-values(/formQuery[@version=$const:SUPPORTED-VERSION and documentType=$document-type and database=$database]/views/view/name/fn:string())
  for $name in $names
    order by $name
    return $name
};

declare function cfg:get-view(
  $query-name as xs:string,
  $document-type as xs:string,
  $view-name as xs:string)
  as element(view)?
{
  /formQuery[@version=$const:SUPPORTED-VERSION and queryName=$query-name and documentType=$document-type]/views/view[name=$view-name]
};


declare function cfg:search-config($source as xs:string, $query as cts:query)
{
  xu:value(fn:concat("cts:search(/", $source, ",", $query, ")"))
};

declare function cfg:delete-document($uri as xs:string) {
  xdmp:document-delete($uri)
};