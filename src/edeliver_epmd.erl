% This module is used as epmd callback and is passed via the `-epmd_module` vm.args attribute.
% It can be used in an epmd-less environment e.g. when running a release in a docker container.
% In this case the release does not use (nor start) epmd for node discovery, but binds the
% aceptor used for distribution to a fixed port, set as ERL_DIST_PORT env, by default 4321.
% This allows to map a fixed distribution port from within the docker container to the host and
% to connect to it from other nodes. 
%
% Known nodes and their ports can be added by the `nodes` `edeliver` application config e.g.
% in the sys.config file of the release or be passed space separated in the EDELIVER_NODES
% environment variable. The port can be specified separated by a `:` if it does not listen
% on the default ERL_DIST_PORT or DEFAULT_DIST_PORT respectively which preceedes the latter.
% e.g.
% ```
% EDELIVER_NODES="foo@bar.local baz@bar.local:4323` \
% ERL_ZFLAGS="-start_epmd false -epmdodule edeliver_epmd" \
% bin/my-app console
% ```
% Starts a my-app node which can connect to foo@bar.local at distribution port 4321 and to
% node baz@bar.local at port 4323. Same can be achieved when setting it in the sys.config
% ```
%  [{kernel, [{net_ticktime. 20}, …]},
%   {edeliver, [{nodes, ['foo@bar.local', 'baz@bar.local:4323']},
%   …]}]
% ```
%
% This module must not output anything, because it is invoked at such an early state of the
% release boot procedure and also the distillery / relx `ping` or `remote_console` commands expect
% a bare `pong` output which could be confused by output of this module.
-module(edeliver_epmd).

-behaviour(gen_server).

-export([start_link/0,
         register_node/3,
         address_please/3,
         port_please/2,
         listen_port_please/2,
         names/1]).

-export([known_nodes/0,
         dist_listen_port/0,
         default_dist_port/0,
         add_node/1,
         add_node/2,
         remove_node/1]).

-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2]).

-include_lib("kernel/include/inet.hrl").

-ifdef(OTP_VERSION).
-if(?OTP_VERSION < 23).
-define(ERL_DIST_VER, 5).  % OTP-22 or (much) older
-else.
-define(ERL_DIST_VER, 6).  % OTP-23 (or maybe newer?)
-endif.
-else.
-define(ERL_DIST_VER, 5).  % OTP-22 or (much) older
-endif.

-record(state, {dist_port   :: inet:port_number(), % contains the port this node binds on. this is usually the same
                                % as default_dist_port except for nodes starting a remote console.
                default_dist_port :: inet:port_number(), % contains the default port nodes bind on and accept connections at
                nodes_ports :: proplists:proplist(), % contains original the node port mapping with host names
                hosts_ports :: proplists:proplist()}). % contains the node port mapping with ip addresses

-define(DEFAULT_DIST_PORT, 4321).

% ------------- pubic api ----------- %

% started automatically by the kernel app if set as `-epmd_module`
start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

known_nodes() ->
  {ok, #state{nodes_ports = NodesPorts, hosts_ports = HostsPorts}} = gen_server:call(?MODULE, get_state),
  case HostsPorts of
    undefined -> NodesPorts;
    _ -> HostsPorts
  end.

% the port this node listens on for distribution
dist_listen_port() ->
  {ok, #state{dist_port = DistPort}} = gen_server:call(?MODULE, get_state),
  DistPort.

% default port where nodes listen on for distribution as long as they run on separate hosts.
default_dist_port() ->
  {ok, #state{default_dist_port = DefaultDistPort}} = gen_server:call(?MODULE, get_state),
  DefaultDistPort.


add_node(Node) when is_atom(Node) ->
  gen_server:call(?MODULE, {add_node, Node}). 

add_node(Node, Port) when is_atom(Node), is_integer(Port) ->
  gen_server:call(?MODULE, {add_node, Node, Port}). 

remove_node(Node) when is_atom(Node) ->
  gen_server:call(?MODULE, {remove_node, Node}). 

% ------------- internal ----------- %

% gets the known nodes from the edeliver app env `nodes`. must be atoms and can
% contain the port number separated by a `:`
nodes_from_edeliver_app_env() ->
  case application:get_env(edeliver, nodes) of
    {ok, Nodes} -> Nodes;
    _ -> []
  end.

% gets the known nodes form the `EDELIVER_NODES` env. 
% nodes can contain the port number separated by a `:`
nodes_from_env_var() ->
  case os:getenv("EDELIVER_NODES") of
    false -> [];
    NodesString -> [list_to_atom(NodeString) || NodeString <- string:split(NodesString, " ", all)]
  end.
  

% gets known node names from erl args
nodes_from_erl_args() ->
  case init:get_argument(remsh) of
   {ok, [[StringNode]]} -> [list_to_atom(StringNode)];
   _ -> []
  end ++
  case init:get_argument(name) of
   {ok, [[StringNode]]} -> [list_to_atom(StringNode)];
   _ -> []
  end ++ 
  case init:get_argument(sname) of
   {ok, [[StringNode]]} -> [list_to_atom(StringNode ++ "@127.0.0.1")];
   _ -> []
  end ++
  lists:foldl(fun(Arg, Acc) -> 
                case Arg of
                  [$-,$-,   $n,$a,$m,$e,$= | StringNode] -> [list_to_atom(StringNode) | Acc];
                  [$-,$-,$s,$n,$a,$m,$e,$= | StringNode] -> [list_to_atom(StringNode  ++ "@127.0.0.1") | Acc];
                  _ -> Acc
                end 
              end, [], init:get_plain_arguments()).

init([]) ->
  % get the port this node (and others by default) binds to
  DistPort = case os:getenv("ERL_DIST_PORT") of
               false ->
                 try
                     {ok, [[StringPort]]} = init:get_argument(erl_epmd_port),
                     list_to_integer(StringPort)                       
                 catch error:_ ->
                    ?DEFAULT_DIST_PORT
                 end;
               PortString ->
                 list_to_integer(PortString)
             end,
  % the port a remote console wants to connect to or use the port other nodes bind to by default
  DefaultDistPort = case os:getenv("DEFAULT_DIST_PORT") of 
                      false ->
                        DistPort;
                      RunningPortString ->
                       list_to_integer(RunningPortString)
                    end,
  % get and store known nodes and their (optional ports)
  NodesPorts = lists:map(fun(CurNode) ->
                  case lists:member($@, atom_to_list(CurNode)) of
                    true  -> case string:split(atom_to_list(CurNode), ":") of
                               [NodeWithPort, Port] ->
                                  {list_to_atom(NodeWithPort), list_to_integer(Port)};
                               [NodeWithoutPort] ->
                                  {list_to_atom(NodeWithoutPort), DefaultDistPort}
                             end;
                    false -> {list_to_atom(atom_to_list(CurNode) ++ [$@] ++ net_adm:localhost()), DefaultDistPort}
                  end
                end, nodes_from_edeliver_app_env() ++ nodes_from_erl_args() ++ nodes_from_env_var()),

  {ok, #state{dist_port = DistPort, default_dist_port = DefaultDistPort, nodes_ports = NodesPorts}}.


register_node(_Name, _Port, _Family) ->
  {ok, rand:uniform(3)}.

port_please(Name, Host) ->
  case gen_server:call(?MODULE, {port_please, Name, Host}) of
      {ok, Port} ->
          {port, Port, ?ERL_DIST_VER};
      _ ->
          {error, noport}
  end.

address_please(Name, Host, AddressFamily) ->
  {ok, Address} = inet:getaddr(Host, AddressFamily),
  case port_please(Name, Address) of
      {port, Port, Version} ->
          {ok, Address, Port, Version};
      {error, noport} ->
          {error, noport}
  end.

listen_port_please(_Name, _Host) ->
  gen_server:call(?MODULE, listen_port).


names(_Hostname) ->
  {error, address}.

handle_call({port_please, Name, Host}, _From, State = #state{nodes_ports = NodesPorts, hosts_ports = HostsPorts, default_dist_port = DefaultDistPort}) ->
  FullNodeName = list_to_atom(Name ++ "@" ++ inet_parse:ntoa(Host)),
  ResolvedHostsPorts = case HostsPorts of
    undefined ->
      lists:map(fun({CurNode, CurPort}) -> 
        [NodeName, HostName] = string:split(atom_to_list(CurNode), "@"),
        Address = case inet:getaddr(HostName, inet) of
          {ok, IPAddress} -> IPAddress;
          {error, _} -> {127,0,0,1} % eg for nonode@nohost for remote console
        end,
        {list_to_atom(NodeName ++ "@" ++ inet_parse:ntoa(Address)), CurPort}
      end, NodesPorts);
    [_|_] -> HostsPorts
  end,
  case proplists:get_value(FullNodeName, ResolvedHostsPorts) of
    undefined -> % assume node runs on default port
      {reply, {ok, DefaultDistPort}, State#state{hosts_ports = ResolvedHostsPorts}};
    Port ->
      {reply, {ok, Port}, State#state{hosts_ports = ResolvedHostsPorts}}
  end;
handle_call({add_node, Node}, From, State = #state{default_dist_port = DefaultDistPort}) ->
  handle_call({add_node, Node, DefaultDistPort}, From, State);
handle_call({add_node, Node, Port}, _From, State = #state{nodes_ports = NodesPorts, hosts_ports = HostsPorts}) ->
  case HostsPorts of
    undefined ->
      {reply, {ok, {Node, Port}}, State#state{nodes_ports = [{Node, Port} | NodesPorts]}};
    [_|_] ->
      [NodeName, HostName] = string:split(atom_to_list(Node), "@"),
      Address = case inet:getaddr(HostName, inet) of
        {ok, IPAddress} -> IPAddress;
        {error, _} -> {127,0,0,1} % eg for nonode@nohost for remote console
      end,
      NewNode = {list_to_atom(NodeName ++ "@" ++ inet_parse:ntoa(Address)), Port},
      {reply, {ok, NewNode}, State#state{hosts_ports = [NewNode | HostsPorts]}}
  end;
handle_call({remove_node, Node}, _From, State = #state{nodes_ports = NodesPorts, hosts_ports = HostsPorts}) ->
  case HostsPorts of
    undefined ->
      NewState = State#state{nodes_ports = NewNodesPorts = [{ExistingNode, ExistingPort} || {ExistingNode, ExistingPort} <- NodesPorts, (io:format("ExistingNode ~p /= Node ~p~n", [ExistingNode, Node]) /= ok) or (ExistingNode /= Node)]},
      {reply, {ok, NewNodesPorts}, NewState};
    [_|_] ->
      NewState = State#state{hosts_ports = NewNodesPorts = [{ExistingNode, ExistingPort} || {ExistingNode, ExistingPort} <- HostsPorts, (io:format("ExistingNode ~p /= Node ~p~n", [ExistingNode, Node]) /= ok) or (ExistingNode /= Node)]},
      {reply, {ok, NewNodesPorts}, NewState}
  end;
handle_call(listen_port, _From, State = #state{dist_port = DistPort}) ->
  {reply, {ok, DistPort}, State};
handle_call(get_state, _From, State = #state{}) ->
  {reply, {ok, State}, State};
handle_call(_Msg, _From, State) ->
  {noreply, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Msg, State) ->
  {noreply, State}.



