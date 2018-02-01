xquery version "1.0-ml";

module namespace endpoints="http://example.com/ns/endpoints";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;

declare namespace rest="http://marklogic.com/appservices/rest";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $endpoints:DEFAULT             as xs:string := "/client/index.html";

declare variable $endpoints:API-AUTH                as xs:string := "/server/endpoints/api-auth.xqy";
declare variable $endpoints:API-DEAUTH              as xs:string := "/server/endpoints/api-auth-deauth.xqy";

declare variable $endpoints:API-USERS-PASS      as xs:string := "/server/endpoints/api-users-pass.xqy";
declare variable $endpoints:API-DETAIL          as xs:string := "/server/endpoints/api-detail.xqy";
declare variable $endpoints:API-GET-XML-DOC     as xs:string := "/server/endpoints/api-get-xml-doc.xqy";
declare variable $endpoints:API-USERS           as xs:string := "/server/endpoints/api-users.xqy";
declare variable $endpoints:API-ADHOC-DATABASES as xs:string := "/server/endpoints/adhoc/api-adhoc-databases.xqy";
declare variable $endpoints:API-ADHOC-SELECTORS as xs:string := "/server/endpoints/adhoc/api-adhoc-selectors.xqy";
declare variable $endpoints:API-SEARCH          as xs:string := "/server/endpoints/adhoc/api-adhoc-search.xqy";
declare variable $endpoints:API-SUGGEST-VALUES  as xs:string := "/server/endpoints/adhoc/api-adhoc-suggest-values.xqy";
declare variable $endpoints:API-ADHOC-WIZARD as xs:string := "/server/endpoints/adhoc/wizard/api-adhoc-query-wizard.xqy";
declare variable $endpoints:API-ADHOC-WIZARD-CREATE as xs:string := "/server/endpoints/adhoc/wizard/api-adhoc-query-wizard-create.xqy";

declare variable $endpoints:API-CHECK-TEMPLATES as xs:string := "/server/endpoints/api-check-templates.xqy";


(: README https://github.com/marklogic/ml-rest-lib :)

declare variable $endpoints:ENDPOINTS as element(rest:options) :=
    <options xmlns="http://marklogic.com/appservices/rest">

        <request uri="^\d+$" redirect="{$endpoints:DEFAULT}" />
        <request uri="^/$" endpoint="{$endpoints:DEFAULT}"/>
        <request uri="^/login$" endpoint="{$endpoints:DEFAULT}"/>
        <request uri="^/adhoc$" endpoint="{$endpoints:DEFAULT}"/>
        <request uri="^/wizard$" endpoint="{$endpoints:DEFAULT}"/>
        <request uri="^/index\.htm" endpoint="{$endpoints:DEFAULT}"/>

        <request uri="^/auth$" endpoint="{$endpoints:API-AUTH}">
            <param name="userid"/>
            <param name="password"/>
            <http method="POST"/>
        </request>
        <request uri="^/deauth$" endpoint="{$endpoints:API-DEAUTH}">
            <http method="POST"/>
        </request>

        <request uri="^/api/users/me" endpoint="{$endpoints:API-USERS}">
            <http method="GET"/>
            <param name="id"/>
        </request>
        <request uri="^/api/users/me$" endpoint="{$endpoints:API-USERS-PASS}">
            <param name="newpassword"/>
            <param name="newpasswordconfirm"/>
            <http method="POST"/>
        </request>
        <request uri="^/api/checkTemplates" endpoint="{$endpoints:API-CHECK-TEMPLATES}">
            <http method="GET"/>
        </request>
        <request uri="^/api/detail/*/*" endpoint="{$endpoints:API-DETAIL}">
            <http method="GET"/>
        </request>
        <request uri="^/api/get-xml-doc/*/*" endpoint="{$endpoints:API-GET-XML-DOC}">
            <http method="GET"/>
        </request>
        <request uri="^/api/adhoc$" endpoint="{$endpoints:API-ADHOC-DATABASES}">
            <http method="GET"/>
        </request>
        <request uri="^/api/adhoc/*/*" endpoint="{$endpoints:API-ADHOC-SELECTORS}">
            <http method="GET"/>
        </request>
        <request uri="^/api/search$" endpoint="{$endpoints:API-SEARCH}">
            <param name="database"/>
            <param name="docType"/>
            <param name="queryName"/>
            <param name="viewName"/>
            { endpoints:numbered-params("id", (1 to 15)) }
            <param name="searchText"/>
            <param name="excludedeleted"/>
            <param name="excludeversions"/>
            <param name="selectedfacet"/>
            <param name="go"/>
            <param name="pagenumber"/>
            <param name="pagination-size"/>
            <param name="exportCsv"/>
            <param name="includeMatches"/>
            <http method="POST"/>
            <http method="GET"/>
        </request>
        <request uri="^/api/suggest-values$" endpoint="{ $endpoints:API-SUGGEST-VALUES }">
            <param name="database"/>
            <param name="rangeIndex"/>
            <param name="qtext"/>
            <http method="GET"/>
        </request>
        <request uri="^/api/wizard/upload$" endpoint="{$endpoints:API-ADHOC-WIZARD}">
            <param name="uploadedDoc"/>
            <param name="mimeType"/>
            <param name="type"/>
            <http method="POST"/>
        </request>
        <request uri="^/api/wizard/create$" endpoint="{$endpoints:API-ADHOC-WIZARD-CREATE}">
            <param name="prefix"/>
            <param name="rootElement"/>
            <param name="fileType"/>
            <param name="queryName"/>
            <param name="viewName"/>
            <param name="queryText"/>
            <param name="database"/>   
            <param name="submit"/>
            {endpoints:numbered-params("formLabelDataType", (1 to 250))}
            {endpoints:numbered-params("formLabel", (1 to 250))}
            {endpoints:numbered-params("formLabelHidden", (1 to 250))}
            {endpoints:numbered-params("formLabelIncludeMode", (1 to 250))}
            {endpoints:numbered-params("columnName", (1 to 250))}
            {endpoints:numbered-params("columnExpr", (1 to 250))}                    
            {endpoints:numbered-params("columnIncludeMode", (1 to 250))}
            <http method="POST"/>
            <http method="GET"/>
        </request>
     </options>;


declare function endpoints:options()
as element(rest:options)
{
  $endpoints:ENDPOINTS
};

declare function endpoints:request(
  $module as xs:string)
as element(rest:request)?
{
  ($endpoints:ENDPOINTS/rest:request[@endpoint = $module])[1]
};

declare function endpoints:resource-for-module($module as xs:string) as xs:string
{
    fn:string(endpoints:request($module)/@uri)
};

declare function endpoints:numbered-params($prefix as xs:string, $seq as xs:int*)
    as element(rest:param)*
{
  for $i in $seq
  return <rest:param name="{ fn:concat($prefix, fn:string($i)) }"/>
};