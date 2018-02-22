xquery version "1.0-ml";
import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";


let $templateExists := xdmp:estimate(cts:search(fn:doc()/formQuery[@version=$const:SUPPORTED-VERSION], cts:directory-query("/adhoc/","infinity"))) ge 1
return 
'
{
	"queryTemplateExists" : '||$templateExists||',
	"isWizardUser" : '||check-user-lib:is-wizard-user()||',
	"isSearchUser" : '||check-user-lib:is-search-user()||'
}
'