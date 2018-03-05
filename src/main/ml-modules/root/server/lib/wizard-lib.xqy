xquery version "1.0-ml";

module namespace wl = "http://marklogic.com/data-explore/lib/wizard-lib";
declare option xdmp:mapping "false";

(: moved from api-adhoc-query-wizard.xqy :)
declare function wl:collapse-xpath($is-json as xs:boolean,$xpath as xs:string){
  let $nodes := fn:tokenize($xpath, "/")
  let $nodescount := fn:count($nodes)
  let $new-xpath :=
    if ($nodescount eq 5) then
      fn:string-join(($nodes[2], $nodes[3], "...", $nodes[last()]), "/")
    else if ($nodescount eq 6) then
      fn:string-join(($nodes[2], $nodes[3], "...", "...", $nodes[last()]), "/")
    else $xpath
  return <span title="{$xpath}">{$new-xpath}</span>
};



