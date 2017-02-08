defmodule Edeliver.Relup.Instructions.FinishRunningRequests do
@moduledoc """
    Notify request processes that a release upgrade starts.

    This upgrade instruction waits a short time until current
    requests finished and notifies the remaining, that a
    code upgrade will appear.  If a `phoenix` version is used
    which supports the upgrade notification feature, the
    remaining requests that did not finish but failed durining
    the upgrade will be replayed with the original request
    when the code upgrade is done. This instruction should be
    used in conjunction with and after the

    `Edeliver.Relup.Instructions.SuspendRanchAcceptors`

    instruction which avoids that new requets are accepted
    during the upgrade.

    To make sure that the http request connections can
    be found on the node, use this instruction after the

    `Edeliver.Relup.Instructions.CheckRanchConnections`

    instruction which will abort the upgrade if the http
    request connections accepted by ranch cannot be found
    in the supervision tree.
  """
  use Edeliver.Relup.RunnableInstruction
  alias Edeliver.Relup.Instructions.CheckRanchAcceptors
  alias Edeliver.Relup.Instructions.CheckRanchConnections

  @doc """
    Appends this instruction to the instructions after the
    "point of no return"

    but before any instruction which
    loads or unloads new code, (re-)starts or stops
    any running processes, or (re-)starts or stops any
    application or the emulator.
  """
  def insert_where, do: &append_after_point_of_no_return/2

  @doc """
    Returns name of the application and the timeout in ms to wait
    until running requests finish.

    These values taken as argument for the `run/1` function
  """
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_atom(name) do
    {name, 500}
  end
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_binary(name) do
    {name |> String.to_atom, 500}
  end

  @doc """
    This module depends on the `Edeliver.Relup.Instructions.CheckRanchAcceptors` and
    the `Edeliver.Relup.Instructions.CheckRanchConnections` module

    which must be loaded before this instruction for upgrades and unload after this instruction
    for downgrades.
  """
  @spec dependencies() :: [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  def dependencies do
    [Edeliver.Relup.Instructions.CheckRanchAcceptors, Edeliver.Relup.Instructions.CheckRanchConnections]
  end

  @doc """
    Waits until the list of processes terminated.

    Waits up to `timeout` ms and the returns the process ids of the processes which are still running
  """
  @spec bulk_wait_for_termination(processes::[pid], timeout::non_neg_integer) :: [pid::pid]
  def bulk_wait_for_termination(_processes = [], _timeout), do: []
  def bulk_wait_for_termination(processes, timeout) do
    proc = self()
    waiting_pid = Process.spawn(fn() ->
      pids_and_monitor_refs = for pid <- processes do
        {pid, :erlang.monitor(:process, pid)}
      end
      wait_fun = fn(pids_and_monitor_refs, wait_fun) ->
        receive do
          {:DOWN, monitor_ref, :process, pid, _reason} ->
            wait_fun.(pids_and_monitor_refs -- [{pid, monitor_ref}], wait_fun)
          :timeout -> send proc, {:remaining, pids_and_monitor_refs |> Enum.map(&(:erlang.element(1, &1)))}
        end
      end
      wait_fun.(pids_and_monitor_refs, wait_fun)
    end, [:link])
    receive do
      :all_terminated -> []
      after timeout ->
        send waiting_pid, :timeout
        receive do
          {:remaining, remaining_pids} -> remaining_pids
        end
    end
  end

  @doc """
    Sends the given event to all processes representing http requests
  """
  @spec notify_running_requests([pid], event::term) :: :ok
  def notify_running_requests([], _event), do: :ok
  def notify_running_requests([pid|remaining_requests], event) do
    send pid, event
    notify_running_requests(remaining_requests, event)
  end


  @doc """
    Waits `timeout` milliseconds until current http requests finished

    and notifies remaining request processes that a code upgrad is running
    and new code will be loaded. This enables phoenix to rerun requests
    which failed during code loading.
  """
  @spec run({otp_application_name::atom, timeout::non_neg_integer}) :: :ok
  def run({otp_application_name, timeout}) do
    info "Waiting up to #{inspect timeout} ms until running requests finished..."
    ranch_listener_sup = CheckRanchAcceptors.ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to wait until requests finished. Ranch listener supervisor not found."
    ranch_connections_sup = CheckRanchConnections.ranch_connections_sup(ranch_listener_sup)
    assume true = is_pid(ranch_connections_sup), "Failed to wait until requests finished. Ranch connections supervisor not found."
    assume true = is_list(connections = CheckRanchConnections.ranch_connections(ranch_connections_sup)), "FFailed to wait until requests finished. No connection processes found."
    request_connections = case CheckRanchConnections.websocket_channel_connections(otp_application_name, connections) do
      [] -> connections
      websocket_connections = [_|_] -> connections -- websocket_connections
      :not_detected -> connections
    end
    requests_count = Enum.count(request_connections)
    if requests_count == 0 do
      info "No requests running."
    else
      info "Waiting for #{inspect requests_count} requests..."
      remaining_requests = bulk_wait_for_termination(request_connections, timeout)
      remaining_requests_count = Enum.count(remaining_requests)
      info "#{inspect requests_count-remaining_requests_count} requets finished."
      if remaining_requests_count > 0 do
        info "#{inspect remaining_requests_count} requests will be restarted after upgrade if they failed."
        notify_running_requests(remaining_requests, :upgrade_started)
      end
    end
  end
end
