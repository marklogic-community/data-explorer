xquery version "1.0-ml";

module namespace nl= "http://marklogic.com/data-explore/lib/namespace-lib";

declare function nl:get-prefix($node as node()) as xs:string? {
    let $node := if ($node instance of document-node() ) then $node/node() else $node
    return if ( $node instance of element() ) then (
            let $qname := fn:node-name($node)
            let $prefix := fn:prefix-from-QName($qname)
            return if ( fn:empty($prefix)) then
                if ( fn:empty(fn:namespace-uri-for-prefix((), $node))) then
                    ()
                else
                    "xmlns"
            else
                $prefix
            ) else
                ()
};

declare function nl:get-path($node as node()) as xs:string?
{
    fn:string-join(
            for $ancestor in $node/ancestor-or-self::*
                let $lname := fn:local-name($ancestor)
                let $prefix := nl:get-prefix($ancestor)
                let $prefix := if ( fn:empty($prefix) ) then
                                   ()
                                else
                                  fn:concat($prefix,":")
                return fn:concat($prefix,$lname)
            , '/')
};

declare function nl:get-prefix-namespace-map($doc as node()) as map:map
{
    let $doc := if ($doc instance of document-node()) then
        $doc/node()
    else
        $doc
    let $ret-map := map:map()
    let $_ :=  for $prefix in fn:in-scope-prefixes($doc)
    return if ($prefix = 'xml') then
        ()
    else if ( fn:empty($prefix) or fn:string-length(fn:normalize-space($prefix)) = 0 ) then
            map:put($ret-map,'xmlns',fn:namespace-uri-for-prefix($prefix, $doc))
        else
            map:put($ret-map,$prefix,fn:namespace-uri-for-prefix($prefix, $doc))
    return $ret-map
};

(: used by profile-nodes to keep track of encountered namespaces :)
declare function nl:resolve-namespace-prefix($qname as xs:QName, $namespaces as map:map) as xs:string*
{
    let $namespace := fn:namespace-uri-from-QName($qname)
    return if (fn:string-length($namespace) le 0) then ()
    else
        if (map:contains($namespaces, $namespace))
        then map:get($namespaces, $namespace)
        else
            let $prefix := fn:prefix-from-QName($qname)
            let $prefix := if ( fn:empty($prefix) and fn:string-length(fn:normalize-space($namespace))>0) then
                "xmlns"
            else $prefix
            return (map:put($namespaces, $namespace, $prefix), $prefix)
};
