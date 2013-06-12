#!/usr/bin/env escript
%%! -noshell -noinput
%% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ft=erlang ts=4 sw=4 et

-define(TIMEOUT, 60000).
-define(INFO(Fmt,Args), io:format(Fmt,Args)).

main([NodeName, Cookie, ReleasePackage]) ->
    TargetNode = start_distribution(NodeName, Cookie),
    case rpc:call(TargetNode, release_handler, unpack_release, [ReleasePackage], ?TIMEOUT) of
       {ok, Vsn} -> ok;
       {error, {existing_release, Vsn}} -> ok;
       {error, UnpackReason} -> ?INFO("Error: ~p~n", [UnpackReason]), Vsn = unknown, halt(1)
    end,
    
    case rpc:call(TargetNode, release_handler, check_install_release, [Vsn], ?TIMEOUT) of
        {ok, _OtherVsn, _Desc} -> ?INFO("~s", [Vsn]);
        {error, {already_installed, Vsn}} -> ?INFO("~p", [Vsn]);
        {error, Reason} -> ?INFO("Error: ~p~n", [Reason]), halt(1)   
    end;
main([NodeName, ReleasePackage]) ->
    main([NodeName, _Cookie=from_home_dir, ReleasePackage]);
main(_) ->
    ?INFO("Missing arguments~n", []),
    init:stop(1).

start_distribution(NodeName, Cookie) ->
    MyNode = make_script_node(NodeName),
    {ok, _Pid} = net_kernel:start([MyNode, shortnames]),
    case Cookie of
        from_home_dir -> ok;
        _ -> erlang:set_cookie(node(), list_to_atom(Cookie))
    end,
    TargetNode = list_to_atom(NodeName),
    case {net_kernel:hidden_connect_node(TargetNode),
          net_adm:ping(TargetNode)} of
        {true, pong} ->
            ok;
        {_, pang} ->
            io:format("Node ~p not responding to pings.\n", [TargetNode]),
            init:stop(1)
    end,
    TargetNode.

make_script_node(Node) ->
    [NodeName, _Host] = string:tokens(Node, "@"),
    list_to_atom(lists:concat([NodeName, "_upgrader_", os:getpid()])).
