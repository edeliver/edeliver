defmodule Edeliver.Relup.Instructions.RerunFailedRequests do
@moduledoc """
    Runs phoenix requests again which failed during hot code upgrade.

    This upgrade instruction notifies request processes
    which were handling requests while new code was loaded
    that they can be rerun if they failed during the upgrade.
    It is required that a `phoenix` version is used
    which supports the upgrade notification feature.
    This instruction should be used in conjunction with and
    after the

    `Edeliver.Relup.Instructions.FinishRunningRequests`

    instruction which notifies the request processes that
    the code upgrade is started.

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
  alias Edeliver.Relup.Instructions.FinishRunningRequests


  @doc """
    Returns name of the application. This name is taken as argument
    for the `run/1` function and is required to access the acceptor processes
    through the supervision tree
  """
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_atom(name) do
    name
  end
  def arguments(_instructions = %Instructions{}, _config = %{name: name}) when is_binary(name)do
    name |> String.to_atom
  end

  @doc """
    This module depends on the `Edeliver.Relup.Instructions.CheckRanchAcceptors`,
    the `Edeliver.Relup.Instructions.CheckRanchConnections` and the
    `Edeliver.Relup.Instructions.FinishRunningRequests` module which must be loaded
    before this instruction for upgrades and unload after this instruction for downgrades.
  """
  @spec dependencies() :: [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  def dependencies do
    [Edeliver.Relup.Instructions.CheckRanchAcceptors,
     Edeliver.Relup.Instructions.CheckRanchConnections,
     Edeliver.Relup.Instructions.FinishRunningRequests]
  end



  @doc """
    Notifies request processes which handled http requests during the
    release upgrade / downgrade that the code loading is finished and
    that requests that failed during the code loading can be now rerun
    with the updated code.
  """
  @spec run(otp_application_name::atom) :: :ok
  def run(otp_application_name) do
    info "Notify running requests that new code was loaded..."
    ranch_listener_sup = CheckRanchAcceptors.ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to notify running requests. Ranch listener supervisor not found."
    ranch_connections_sup = CheckRanchConnections.ranch_connections_sup(ranch_listener_sup)
    assume true = is_pid(ranch_connections_sup), "Failed to notify running requests. Ranch connections supervisor not found."
    assume true = is_list(connections = CheckRanchConnections.ranch_connections(ranch_connections_sup)), "FFailed to wait until requests finished. No connection processes found."
    request_connections = case CheckRanchConnections.websocket_channel_connections(otp_application_name, connections) do
      [] -> connections
      websocket_connections = [_|_] -> connections -- websocket_connections
      :not_detected -> connections
    end
    requests_count = Enum.count(request_connections)
    if requests_count == 0 do
      info "No requests to notify."
    else
        info "#{inspect requests_count} requests will be restarted if they failed."
        FinishRunningRequests.notify_running_requests(request_connections, :upgrade_finished)
    end
  end
end
