xquery version "1.0-ml";

module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils";


declare function xu:eval($xquery as xs:string,
   $vars as item()*) as item()* {

   xdmp:eval($xquery, $vars)
   
};

declare function xu:eval($xquery as xs:string,
   $vars as item()*,
   $options) as item()* {

   xdmp:eval($xquery, $vars, $options)
	
};

declare function xu:invoke($path as xs:string,
   $vars as item()*,
   $options) as item()* {
	xdmp:invoke($path, $vars, $options)
};

declare function xu:invoke-function($func,
      $options as element()){
   xdmp:invoke-function(
      $func, $options
   )
};


declare function xu:value($expr as xs:string) as item()* {
   xdmp:value($expr)
};

declare function xu:value($expr as xs:string,
   $map as map:map?,
   $context as item()?) as item()* {

   xu:value($expr, $map)
};

declare function xu:value($expr as xs:string,
   $map as map:map?) as item()* {

   xdmp:value($expr, $map)
};

declare function xu:get-server-field($name) as item()* {
   xdmp:get-server-field($name)
};

declare function xu:set-server-field($name as xs:string, $value as item()*) as item()* {
   xdmp:set-server-field($name, $value)
};

declare function xu:document-insert(
                  $uri as xs:string,
                  $root as node(),
                  $permissions as element(sec:permission)*) {
   xdmp:document-insert($uri, $root, $permissions)
};

declare function xu:document-insert(
                  $uri as xs:string,
                  $root as node()) {
   xdmp:document-insert($uri, $root)
};


