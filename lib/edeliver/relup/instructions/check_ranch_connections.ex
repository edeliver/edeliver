defmodule Edeliver.Relup.Instructions.CheckRanchConnections do
  @moduledoc """
    This upgrade instruction checks whether the running ranch connections can be found.

    This instruction will cause the upgrade to be canceled if the ranch connections
    cannot be found and because it is insterted before the "point of no return"
    it will run twice, once when checking the relup and once when executing the relup.

    If `Phoenix.PubSub.PG2` is used as pubsub backend for phoenix channels,
    running websocket processes will be detected and suspended by the

    `Edeliver.Relup.Instructions.SuspendChannels`

    instruction during the upgrade and resumed by the

    `Edeliver.Relup.Instructions.ResumeChannels` instruction

    after the upgrade / downgrade of the node.
  """
  use Edeliver.Relup.RunnableInstruction
  alias Edeliver.Relup.Instructions.CheckRanchAcceptors

  @doc """
    Inserts the instruction before the point of no return.

    This causes the release handler to abort the upgrade
    already when running `:release_handler.check_install_release/1`
    if this instruction fails.
  """
  def insert_where, do: &insert_before_point_of_no_return/2

  @doc """
    Returns name of the application.

    This name is taken as argument for the `run/1` function
    and is required to access the acceptor processes through the supervision tree
  """
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_atom(name) do
    name
  end
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_binary(name) do
    name |> String.to_atom
  end

  @doc """
    This module requires the `Edeliver.Relup.Instructions.CheckRanchAcceptors` module

    which must be loaded before this instruction for upgrades and unload after this
    instruction for downgrades.
  """
  @spec dependencies() :: [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  def dependencies do
    [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  end


  @doc """
    Gets the pid of the supervisor which supervises the ranch connections.

    If it cannot be found as child of the given ranch listener supervisor it
    throws and logs an error.
  """
  @spec ranch_connections_sup(ranch_listener_sup::pid) :: pid
  def ranch_connections_sup(ranch_listener_sup) do
    matching_children = Supervisor.which_children(ranch_listener_sup) |> Enum.filter(fn(child) ->
      case child do
        {:ranch_conns_sup, _pid, _type, [:ranch_conns_sup]} -> true
        _ -> false
      end
    end)
    assume [{_, ranch_acceptors_sup_pid, _, _}] = matching_children, "Failed to detect ranch socket acceptors. Ranch acceptors supervisor not found."
    ranch_acceptors_sup_pid
  end

  @doc """
    Gets the process ids of the ranch socket connections if there are any.
  """
  @spec ranch_connections(ranch_acceptors_sup::pid) :: [:supervisor.child_id]
  def ranch_connections(ranch_acceptors_sup) do
    acceptor_pids = Supervisor.which_children(ranch_acceptors_sup) |> List.foldr([], fn child, acc ->
      case child do
         {_child_id = :cowboy_protocol, pid, :worker, [:cowboy_protocol]} -> [pid|acc]
        _ -> acc
      end
    end)
    acceptor_pids
  end


  # Checks whether the given `supervisor` contains exactly one child matching the given `child_id`,
  # assigns the pid of the child to `var` and continues executing `instructions`. If no child
  # or several childs with the id was/were found, it returns `:not_detected`.
  @spec supervised_child_with_id_or_return_not_detected(supervisor::pid, child_id::term, var::term, instructions::term) :: term | :not_detected
  defmacrop supervised_child_with_id_or_return_not_detected(supervisor, child_id, var, instructions) do
    quote do
        case Supervisor.which_children(unquote(supervisor)) |> List.foldr([], fn child, acc ->
          case child do
             {unquote(child_id), pid, _type, _} -> [pid|acc]
            _ -> acc
          end
         end) do
          [unquote(var)] when is_pid(unquote(var)) ->
              [do: result] = unquote(instructions)
              result
          _ -> :not_detected
        end
    end
  end


  @doc """
    Returns the pids of the connections which are websocket connections for channels.

    This detection works only if `Phoenix.PubSub.PG2` is used as pubsub backend. If detection fails,
    it returns `:not_detected`. Knowing which processes of the known connections are websockets is useful
    because they should be suspended during the hot code upgrade and resumed again afterwards.
    If detection fails, websocket connections must be treated as "normal" http request connections.
    Detection of websocket connections is not possible either by the phoenix api nor by the cowboy / ranch api.
    Thats why this function takes the processes that are monitored by the `Phoenix.PubSub.Local` process
    and are a subset of the detected connections as websocket connections for channels. The lookup for
    `Phoenix.PubSub.Local` process is dones by searching the supervision tree of the application for:

          `Phoenix.Endpoint` -> `Phoenix.PubSub.PG2` -> `Phoenix.PubSub.LocalSupervisor` -> `Supervisor` -> `Phoenix.PubSub.Local`
  """
  @spec websocket_channel_connections(otp_application_name::atom, connections::[pid]) :: [] | [pid] | :not_detected
  def websocket_channel_connections(otp_application_name, connections) do
    endpoint_pid = CheckRanchAcceptors.endpoint(otp_application_name)
    assume true = is_pid(endpoint_pid), "Failed to detect websocket connections. Phoenix endpoint not found."
    supervised_child_with_id_or_return_not_detected endpoint_pid, Phoenix.PubSub.PG2, pubsub_sup do
      supervised_child_with_id_or_return_not_detected pubsub_sup, Phoenix.PubSub.LocalSupervisor, local_sup do
        supervised_child_with_id_or_return_not_detected local_sup, 0, supervisor do
          supervised_child_with_id_or_return_not_detected supervisor, Phoenix.PubSub.Local, pubsub_local do
            case :erlang.process_info(pubsub_local, :monitors) do
              {:monitors, monitors} when is_list(monitors) ->
                monitored_pids = List.foldr(monitors, [], fn monitor, acc ->
                  case monitor do
                    {:process, pid} -> [pid|acc]
                    _ -> acc
                  end
                end)
                # if the connection as a linked `Phoenix.Socket` process
                # which is monitored by the `Phoenix.PubSub.Local` pubsub backend
                # it's a websocket connected to a phoenix channel
                Enum.filter(connections, fn connection ->
                  case :erlang.process_info(connection, :links) do
                    {:links, pids_and_ports = [_,_|_]} -> # must have at least two links: one to the supervisor and one to the `Phoenix.Socket`
                      Enum.any?(pids_and_ports, &(is_pid(&1) and Enum.member?(monitored_pids, &1)))
                    _ -> false
                  end
                end)
              _ -> :not_detected
            end
          end
        end
      end
    end
  end

  @doc """
    Checks whether the ranch connections can be found.

    If not the upgrade will be canceled. This function runs twice because it is executed before
    the "point of no return", once when checking the relup and once when executing the relup.
    It also tries to detect the websocket processes if the `Phoenix.PubSub.PG2` pubsub
    backend is used for phoenix websocket channels. It will not fail if that detection
    is not possible, but a warning is printed
  """
  @spec run(otp_application_name::atom) :: :ok
  def run(otp_application_name) do
    info "Checking whether ranch socket connections can be found..."
    ranch_listener_sup = CheckRanchAcceptors.ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to detect ranch socket connections. Ranch listener supervisor not found."
    ranch_connections_sup = ranch_connections_sup(ranch_listener_sup)
    assume true = is_pid(ranch_connections_sup), "Failed to detect ranch socket connections. Ranch connections supervisor not found."
    assume true = is_list(connections = ranch_connections(ranch_connections_sup)), "Failed to detect ranch socket connections. No connection processes found."
    info "Found #{inspect Enum.count(connections)} ranch connections."
    case websocket_channel_connections(otp_application_name, connections) do
      [] -> info "Detected that no websockets are connected to channels."
      websocket_connections = [_|_] -> info "#{inspect Enum.count(websocket_connections)} out of #{inspect Enum.count(connections)} connections are websocket channel connections."
      :not_detected ->
        warn  "Cannot detect websocket channel connections."
        debug "They won't be suspended but treated as normal http request connections."
        debug "Detection is possible only if 'Phoenix.PubSub.PG2' is used as pubsub backend."
    end
  end
end
