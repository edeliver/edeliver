defmodule Edeliver.Relup.Instructions.SuspendChannels do
  @moduledoc """
    This upgrade instruction suspends the websocket processes

    connected to phoenix channels to avoid that  new channel
    events will be processed  during the code upgrade / downgrade
    process. It will be appended to the instructions after the "point of no return"
    but before any application code is reloaded. It should be
    used in conjunction with and after the

    `Edeliver.Relup.Instructions.SuspendRanchAcceptors`

    instruction which avoids that new websockets processes for
    phoenix channels are started.

    To make sure that the websocket connections can
    be found on the  node, use this instruction after the

    `Edeliver.Relup.Instructions.CheckRanchConnections`

    instruction which will abort the upgrade if ranch
    (websocket) connections cannot be found in the supervision
    tree. Use the

    `Edeliver.Relup.Instructions.ResumeRanchAcceptors`

    instruction at the end of your instructions list to
    resume the websocket processes and reenable handling
    channel messages.

    Suspending and resuming websocket processes for
    phoenix channels requires a recent phoenix version
    which handles sys events for websockets. It also
    requires that the builtin phoenix pubsub backend
    `Phoenix.PubSub.PG2` is used for the phoenix channels.

  """
  use Edeliver.Relup.RunnableInstruction
  alias Edeliver.Relup.Instructions.CheckRanchAcceptors
  alias Edeliver.Relup.Instructions.CheckRanchConnections

  @doc """
    Appends this instruction to the instructions after the
    "point of no return" but before any instruction which
    loads or unloads new code, (re-)starts or stops
    any running processes, or (re-)starts or stops any
    application or the emulator.
  """
  def insert_where, do: &append_after_point_of_no_return/2

  @doc """
    Returns name of the application. This name is taken as argument
    for the `run/1` function and is required to access the acceptor processes
    through the supervision tree
  """
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_atom(name) do
    name
  end
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_binary(name) do
    name |> String.to_atom
  end

  @doc """
    This module depends on the `Edeliver.Relup.Instructions.CheckRanchAcceptors` and
    the `Edeliver.Relup.Instructions.CheckRanchConnections` module which must be loaded
    before this instruction for upgrades and unload after this instruction for downgrades.
  """
  @spec dependencies() :: [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  def dependencies do
    [Edeliver.Relup.Instructions.CheckRanchAcceptors, Edeliver.Relup.Instructions.CheckRanchConnections]
  end

  @doc """
    Suspends a list of processes. Because suspending a process might take a while depending on the length
    of the message queue or duration of current operation processed by the pid, suspending is done
    asynchronously for each process by spawing a new process which calls `:sys.suspend/2` and then waiting
    for all results before returning from this function. Be careful when using `:infinity` as timeout,
    because this function might hang for infinite time if one of the process does not handle sys events.
  """
  @spec bulk_suspend(processes::[pid], timeout::pos_integer|:infinity) :: :ok | {:errors, count::pos_integer, [{pid::pid, reason::term}]} | :not_supported
  def bulk_suspend(processes, timeout \\ 1000) do
    pids_and_monitor_refs = for pid <- processes do
      spawned_pid = :proc_lib.spawn(fn ->
        :ok = :sys.suspend(pid, timeout)
      end)
      {pid, spawned_pid, :erlang.monitor(:process, spawned_pid)}
    end
    result = Enum.reduce(pids_and_monitor_refs, {0, 0, []}, fn({pid, spawned_pid, monitor_ref}, {errors_count, not_supported_count, errors}) ->
      receive do
        {:DOWN, ^monitor_ref, :process, ^spawned_pid, reason} ->
          case reason do
            :normal -> {errors_count, not_supported_count, errors}
            error = {:noproc, {:sys, :suspend, [^pid, ^timeout]}}  -> {errors_count+1, not_supported_count+1, [{pid, error}|errors]}
            error = {:timeout, {:sys, :suspend, [^pid, ^timeout]}} -> {errors_count+1, not_supported_count+1, [{pid, error}|errors]}
            error -> {errors_count+1, not_supported_count, [{pid, error}|errors]}
          end
      end
    end)
    case result do
      {_errors_count = 0, _not_supported_count = 0, _errors = []} -> :ok
      {not_supported_count, not_supported_count, _errors = [_|_]} when length(processes) == not_supported_count -> :not_supported
      {errors_count, _not_supported_count, errors} -> {:errors, errors_count, Enum.reverse(errors)}
    end
  end


  @doc """
    Suspends all websocket channels to avoid handling new channel events
    during the upgrade. This is possible only in recent phoenix versions
    since handling sys events is required for suspending. If an older version
    is used, a warning is printed that suspending is not supported.
  """
  @spec run(otp_application_name::atom) :: :ok
  def run(otp_application_name) do
    info "Suspending phoenix websocket channels..."
    ranch_listener_sup = CheckRanchAcceptors.ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to suspend phoenix websocket channels. Ranch listener supervisor not found."
    ranch_connections_sup = CheckRanchConnections.ranch_connections_sup(ranch_listener_sup)
    assume true = is_pid(ranch_connections_sup), "Failed to suspend phoenix websocket channels. Ranch connections supervisor not found."
    assume true = is_list(connections = CheckRanchConnections.ranch_connections(ranch_connections_sup)), "Failed to suspend phoenix websocket channels. No connection processes found."
    case CheckRanchConnections.websocket_channel_connections(otp_application_name, connections) do
      [] -> info "No websocket connections for phoenix channels are running."
      websocket_connections = [_|_] ->
        websocket_connections_count = Enum.count(websocket_connections)
        info "Suspending #{inspect websocket_connections_count} websocket connections..."
        case bulk_suspend(websocket_connections) do
          :ok -> info "Suspended #{inspect websocket_connections_count} websocket connections."
          :not_supported ->
            warn "Suspending websocket connections for phoenix channels is not supported."
            debug "#{inspect websocket_connections_count} websockets were not suspended."
            debug "Please upgrade the 'phoenix' dependeny to a newer version which supports handling sys events for websockets."
            debug "Not suspended websockets might crash during the code upgrade."
          {:errors, errors_count, _errors} ->
            succeeded_count = websocket_connections_count - errors_count
            warn "Suspended #{inspect succeeded_count} of #{inspect websocket_connections_count} websocket connections. #{inspect errors_count} failed."
            debug "#{inspect errors_count} not suspended websockets might crash during the code upgrade."
        end
      :not_detected ->
        warn  "Cannot detect websocket channel connections."
        debug "They won't be suspended but treated as normal http request connections."
        debug "Detection is possible only if 'Phoenix.PubSub.PG2' is used as pubsub backend."
    end
  end

end
