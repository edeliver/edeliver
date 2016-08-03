defmodule Edeliver.Relup.Instructions.ResumeChannels do
@moduledoc """
    This upgrade instruction resumes the websocket processes

    connected to phoenix channels when the upgrade is done
    to continue handling channel events. Use this instruction
    at the end of the upgrade modification if the

    `Edeliver.Relup.Instructions.SuspendChannels`

    is used at the beginning. Make sure that it is used before
    the

     `Edeliver.Relup.Instructions.ResumeRanchAcceptors`

    instruction to avoid that recently started websockets
    which were not suspendet are tried to be resumed.

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
    Returns name of the application.

    This name is taken as argument for the `run/1` function and is required
    to access the acceptor processes through the supervision tree
  """
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_atom(name) do
    name
  end
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_binary(name) do
    name |> String.to_atom
  end

  @doc """
    This module depends on the `Edeliver.Relup.Instructions.CheckRanchAcceptors` and
    the `Edeliver.Relup.Instructions.CheckRanchConnections` module

    which must be loaded before this instruction for upgrades and unloaded
    after this instruction for downgrades.
  """
  @spec dependencies() :: [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  def dependencies do
    [Edeliver.Relup.Instructions.CheckRanchAcceptors, Edeliver.Relup.Instructions.CheckRanchConnections]
  end

  @doc """
    Resumes a list of processes.

    Because resume a process might take a while depending on the length
    of the message queue or duration of current operation processed by the pid, suspending is done
    asynchronously for each process by spawing a new process which calls `:sys.resume/2` and then waiting
    for all results before returning from this function. Be careful when using `:infinity` as timeout,
    because this function might hang for infinite time if one of the process does not handle sys events.
  """
  @spec bulk_resume(processes::[pid], timeout::pos_integer|:infinity) :: :ok | {:errors, count::pos_integer, [{pid::pid, reason::term}]} | :not_supported
  def bulk_resume(processes, timeout \\ 1000) do
    pids_and_monitor_refs = for pid <- processes do
      spawned_pid = :proc_lib.spawn(fn ->
        :ok = :sys.resume(pid, timeout)
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
    Resumes all websocket channels

    to continue handling channel events after the upgrade. This is possible
    only in recent phoenix versions since handling sys events is required for resuming.
    If an older version is used, a warning is printed that suspending is not supported.
  """
  @spec run(otp_application_name::atom) :: :ok
  def run(otp_application_name) do
    info "Resuming phoenix websocket channels..."
    ranch_listener_sup = CheckRanchAcceptors.ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to resume phoenix websocket channels. Ranch listener supervisor not found."
    ranch_connections_sup = CheckRanchConnections.ranch_connections_sup(ranch_listener_sup)
    assume true = is_pid(ranch_connections_sup), "Failed to resume phoenix websocket channels. Ranch connections supervisor not found."
    assume true = is_list(connections = CheckRanchConnections.ranch_connections(ranch_connections_sup)), "Failed to resume phoenix websocket channels. No connection processes found."
    case CheckRanchConnections.websocket_channel_connections(otp_application_name, connections) do
      [] -> info "No websocket connections for phoenix channels are running."
      websocket_connections = [_|_] ->
        websocket_connections_count = Enum.count(websocket_connections)
        info "Resuming #{inspect websocket_connections_count} websocket connections..."
        case bulk_resume(websocket_connections) do
          :ok -> info "Resumed #{inspect websocket_connections_count} websocket connections."
          :not_supported ->
            warn "Resuming websocket connections for phoenix channels is not supported."
          {:errors, errors_count, _errors} ->
            succeeded_count = websocket_connections_count - errors_count
            warn "Resumed #{inspect succeeded_count} of #{inspect websocket_connections_count} websocket connections. #{inspect errors_count} failed."
            debug "#{inspect errors_count} not resumed websockets might still hang for a while or might have been crashed."
        end
      :not_detected ->
        warn "Resuming websocket connections for phoenix channels is not supported because websocket connections cannot be detected."
    end
  end

end
