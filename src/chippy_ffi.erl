-module(chippy_ffi).
-export([port_is_available/2]).

port_is_available(Host, Port) ->
    Address = case Host of
        <<"localhost">> -> {127, 0, 0, 1};
        _ ->
            {ok, Parsed} = inet:parse_address(binary_to_list(Host)),
            Parsed
    end,
    Options = [binary, {active, false}, {ip, Address}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Options) of
        {ok, Socket} ->
            ok = gen_tcp:close(Socket),
            true;
        {error, _Reason} ->
            false
    end.
