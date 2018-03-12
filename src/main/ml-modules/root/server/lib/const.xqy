xquery version "1.0-ml";


module namespace const = "http://www.marklogic.com/data-explore/lib/const";
declare option xdmp:mapping "false";
declare variable $const:DEFAULT-NAMESPACE-PREFIX := "default_ns";

declare variable $const:DEFAULT-VIEW-NAME := "DefaultView";

declare variable $const:SUPPORTED-VERSION := "1.0.0";

declare variable $const:FILE_TYPE_XML as xs:string := "0";
declare variable $const:FILE_TYPE_JSON as xs:string := "1";

declare variable $const:DATA_TYPE_TEXT as xs:string := "text";
declare variable $const:DATA_TYPE_NUMBER as xs:string := "number";
declare variable $const:DATA_TYPE_BOOLEAN as xs:string := "boolean";

declare variable $const:INTEGER_MAX as xs:integer := xs:integer(9223372036854775807);