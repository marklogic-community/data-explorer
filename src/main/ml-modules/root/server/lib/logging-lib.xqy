xquery version "1.0-ml";

module namespace ll= "http://marklogic.com/data-explore/lib/logging-lib";

declare option xdmp:mapping "false";

declare private variable $ll:TRACE := "data-explorer";
declare private variable $ll:TRACE-DETAILS := "data-explorer-detail";

declare function ll:trace(
        $value as item()*
) as empty-sequence()
{
    if (xdmp:trace-enabled($ll:TRACE)) then
         xdmp:trace($ll:TRACE,(ll:get-extra-info(),$value))
    else
        ()
};

declare function ll:trace-details(
        $value as item()*
) as empty-sequence()
{
    if (xdmp:trace-enabled($ll:TRACE-DETAILS)) then
        xdmp:trace($ll:TRACE-DETAILS,(ll:get-extra-info(),$value))
    else
        ()
};

declare private function ll:get-extra-info(
) as xs:string?
{
    try {
        "database=" || xdmp:database-name(xdmp:database()) || " tx=" || xdmp:transaction() || " mode=" || xdmp:get-transaction-mode() || " user=" || xdmp:get-current-user() ||
        (
            if (xdmp:trace-enabled($ll:TRACE-DETAILS))
            then (
                let $frame :=
                    try {fn:error()}
                    catch ($e) {
                    (: Return the first frame that is not about logging :)
                        ($e/error:stack/error:frame[error:uri eq "/server/lib/logging-lib.xqy"][fn:last()]/following-sibling::error:frame)[1]
                    }
                return " uri=" || $frame/error:uri || " line=" || $frame/error:line || " op=" || $frame/error:operation
            )
            else ()
        )
    } catch ($e) {
        xdmp:log($e,"error")
    }
};