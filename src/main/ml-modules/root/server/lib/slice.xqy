xquery version "1.0-ml";

module namespace slice = "http://marklogic.com/transitive-closure-slice";
import module namespace xu = "http://marklogic.com/data-explore/lib/xdmp-utils" at "/server/lib/xdmp-utils.xqy"; 

declare variable $MAX-DEPTH := 1;

declare variable $NS-MAP :=
<slice:slice-lookup>
  <slice:namespaces>
    <slice:namespace>
      <slice:abbrv>p</slice:abbrv>
      <slice:uri>http://persistence.ffe.cms.hhs.gov</slice:uri>
    </slice:namespace>
    <slice:namespace>
      <slice:abbrv>bpb</slice:abbrv>
      <slice:uri>http://base.persistence.base.cms.hhs.gov</slice:uri>
    </slice:namespace>
    <slice:namespace>
      <slice:abbrv>pb</slice:abbrv>
      <slice:uri>http://persistence.base.cms.hhs.gov</slice:uri>
    </slice:namespace>
  </slice:namespaces>
  <slice:from>
    <slice:type>insurancePlanPolicy</slice:type>
    <slice:to>
      <slice:type>p:insurancePlan</slice:type>
      <slice:from-field>p:selectedInsurancePlan</slice:from-field>
      <slice:to-field>p:insurancePlanIdentifier</slice:to-field>
    </slice:to>
    <slice:to>
      <slice:type>p:insuranceApplication</slice:type>
      <slice:from-field>p:originatingInsuranceApplicationIdentifier</slice:from-field>
      <slice:to-field>bpb:objectIdentifier</slice:to-field>
    </slice:to>
  </slice:from>
  <slice:from>
    <slice:type>insuranceApplication</slice:type>
    <slice:to>
      <slice:type>p:exchangeUser</slice:type>
      <slice:from-field>p:exchangeUserIdentifier</slice:from-field>
      <slice:to-field>bpb:objectIdentifier</slice:to-field>
    </slice:to>
    <slice:to>
      <slice:type>pb:systemUser</slice:type>
      <slice:from-field>p:systemUserName</slice:from-field>
      <slice:to-field>pb:systemUserLoginName</slice:to-field>
    </slice:to>
    <slice:to>
      <slice:type>p:person</slice:type>
      <slice:from-field>p:personTrackingNumber</slice:from-field>
      <slice:to-field>p:personTrackingNumber</slice:to-field>
    </slice:to>
    <slice:to>
      <slice:type>p:userReportedExemption</slice:type>
      <slice:from-field>p:personTrackingNumber</slice:from-field>
      <slice:to-field>p:exemptedPersonTrackingNumber</slice:to-field>
    </slice:to>
    <slice:to>
      <slice:type>p:exemptionApplication</slice:type>
      <slice:from-field>p:personTrackingNumber</slice:from-field>
      <slice:to-field>p:exemptedPersonTrackingNumber</slice:to-field>
    </slice:to>
  </slice:from>
</slice:slice-lookup>;

declare variable $SEEN-URIS := map:map();

declare function slice:objectQuery($parentQNTs as xs:QName*, $idElementQNT as xs:QName, $ids as xs:string*) {
  let $parentQNT := head($parentQNTs)
  let $rest := tail(tail($parentQNTs))
  return
    if ($rest)
    then cts:element-query($parentQNT, slice:objectQuery($rest, $idElementQNT, $ids)) (: wrap the rest in an elem-q :)
    else cts:element-query($parentQNT, cts:element-value-query($idElementQNT, $ids)) (: concrete elem-q(e-v-q(ids))) :)
  (: TODO - for some list of range-indexed keys, use element-range-query(qname, "=", val) :)
};

declare function slice:getObjects($toDocQNT as xs:QName, $toElemQNT as xs:QName, $ids, $database as xs:string) as element()* {
  if ($ids) 
  then
    switch($toDocQNT)
    case ("ns:specialobject") return cts:search(/foo, (), "score-zero", 0) ! element()   (: special handling :)
    default return
      let $q :=  slice:objectQuery($toDocQNT, $toElemQNT, $ids)
      let $LOG := xdmp:log("querying for children using: " || $q)
      let $results := slice:searchAgainst($q, $database)
      let $check := if (count($results) ge 500) then error(xs:QName("TOOMANY"), "at or over 500") else ()  (: TODO - maybe don't fail? :)
      return $results
  else (xdmp:log("No ids for to="||$toDocQNT || " toElem=" || $toElemQNT))
};

declare function slice:searchAgainst($query,$database as xs:string){
  xu:eval(
    '
    xquery version "1.0-ml";
    declare variable $query external;
    cts:search(doc(), $query, "score-zero", 0)[1 to 500] ! element()
    ', 
    ((xs:QName("query"),$query)),
    <options xmlns="xdmp:eval">
        <database>{xdmp:database($database)}</database>
      </options>
  )
};

declare function slice:removeCycles($roots) {
  for $r in $roots
    let $uri := base-uri($r)
    return 
      if (map:get($SEEN-URIS, $uri))
      then () (: r is already in the results :)
      else    (: r is new. cache it and return as non-cyclical :)
        let $cache := map:put($SEEN-URIS, $uri, true())
        return $r  
};

declare function slice:getQName($field, $mapping as element(slice:slice-lookup)){
  let $prefix := substring-before($field, ":")
  let $namespace := $mapping/slice:namespaces/slice:namespace[slice:abbrv/text() = $prefix]/slice:uri
  return fn:QName($namespace,$field)
};

(: get all the linked documents based on the mappings :)
(: get all the linked documents based on the mappings :)
declare function slice:getNewRelatedObjects($from as element(), $mapping as element(slice:slice-lookup), $database as xs:string) as element()* {
  let $type := local-name($from)
  let $toSpecs := $mapping/slice:from[slice:type/text() = $type]/slice:to
  for $spec in $toSpecs           
    let $fromQNT := $spec/slice:from-field
    let $toElemQNT := $spec/slice:type
    let $toElemQN := slice:getQName($toElemQNT,$mapping)
    let $toQNT := $spec/slice:to-field
    let $toQN := slice:getQName($toQNT,$mapping)
    let $fromQN := slice:getQName($fromQNT,$mapping)
    let $ids := $from//element()[node-name(.) eq $fromQN]/text()  (: find the bpb:objectIdentifier text in the from doc :)
    let $LOG := xdmp:log("got ids using" || $fromQN|| " from " || base-uri($from) || " for QN " || $toElemQNT ||"/" || $toQNT || "=" || string-join($ids, ","))
    let $related := slice:getObjects($toElemQN, $toQN, $ids, $database)
    let $LOG := xdmp:log("got related docs: "|| string-join($related/base-uri(), ","))
    let $new := slice:removeCycles($related)  (: remove any items already retrieved :)
    return $new
};
declare function slice:getAllRelatedObjectsRecurse($roots, $depthSoFar, $mapping as element(slice:slice-lookup), $database as xs:string) {
  xdmp:log("getAllRelatedObjects for " || string-join($roots/base-uri(), ",") || "depth:" ||$depthSoFar),
  for $r in $roots
  let $newRelated := slice:getNewRelatedObjects($r, $mapping, $database)
  let $log := if ($newRelated) then () else xdmp:log("no new related objects. will stop.")
  return 
    if ($depthSoFar lt $MAX-DEPTH and $newRelated) 
    then 
      let $children := slice:getAllRelatedObjectsRecurse($newRelated, $depthSoFar +1, $mapping, $database)
      return ($newRelated, $children)
    else (
      xdmp:log("Stopping recursion into related object graph at depth "||$depthSoFar),
      $newRelated  (:  TODO !!!!!!!!!!!!  somewhere, keep the $roots that were already found :)
      )
};

declare function slice:getAllRelatedObjects($root as element(), $mapping as element(slice:slice-lookup), $database as xs:string) {
  let $store := slice:removeCycles($root) (: no cycle yet, but want to store the URI of the root too :)
  return ($root, slice:getAllRelatedObjectsRecurse($root, 0, $mapping, $database))
};

declare function slice:getAllRelatedObjectsWithDefaultMap($document,$db as xs:string){
  slice:getAllRelatedObjects($document, $NS-MAP, $db)
};