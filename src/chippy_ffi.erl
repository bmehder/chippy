-module(chippy_ffi).
-export([probe_port/2]).

probe_port(Host, Port) ->
    Address = case Host of
        <<"localhost">> -> {ok, {127, 0, 0, 1}};
        _ -> inet:parse_address(binary_to_list(Host))
    end,
    case Address of
        {ok, Ip} -> probe_address(Ip, Port);
        {error, Reason} -> {bind_failed, atom_to_binary(Reason)}
    end.

probe_address(Address, Port) ->
    Options = [binary, {active, false}, {ip, Address}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Options) of
        {ok, Socket} ->
            ok = gen_tcp:close(Socket),
            available;
        {error, eaddrinuse} ->
            address_in_use;
        {error, Reason} ->
            {bind_failed, atom_to_binary(Reason)}
    end.
