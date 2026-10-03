-module(chippy_ffi).
-export([port_is_available/1]).

port_is_available(Port) ->
    Options = [binary, {active, false}, {ip, {127, 0, 0, 1}}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Options) of
        {ok, Socket} ->
            ok = gen_tcp:close(Socket),
            true;
        {error, _Reason} ->
            false
    end.
