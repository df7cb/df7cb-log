create function mwc_multi(call text)
    returns text
    language sql
    return substring(call from length(call));

comment on function mwc_multi is 'Get last character from call';
