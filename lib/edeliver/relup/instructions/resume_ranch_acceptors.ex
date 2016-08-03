defmodule Edeliver.Relup.Instructions.ResumeRanchAcceptors do
 @moduledoc """
    This upgrade instruction resumes the ranch acceptors

    which were suspended by the

    `Edeliver.Relup.Instructions.SuspendRanchAcceptors`

    instruction at the beginning of the upgrade.
    Because real suspending of ranch acceptors
    is not possible because ranch acceptors do not handle sys
    messages, they were actually terminated and are restarted
    by this relup instruction.
  """
  use Edeliver.Relup.RunnableInstruction
  alias Edeliver.Relup.Instructions.CheckRanchAcceptors

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
    This module requires the `Edeliver.Relup.Instructions.CheckRanchAcceptors` module

    which must be loaded before this instruction for upgrades and unload after this
    instruction for downgrades.
  """
  @spec dependencies() :: [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  def dependencies do
    [Edeliver.Relup.Instructions.CheckRanchAcceptors]
  end

  @doc """
    Resumes the ranch acceptor supervisor and restarts all ranch acceptors

    to enable accepting new requests / connections again after the upgrade.
  """
  @spec run(otp_application_name::atom) :: :ok
  def run(otp_application_name) do
    info "Resuming ranch socket acceptors..."
    ranch_listener_sup = CheckRanchAcceptors.ranch_listener_sup(otp_application_name)
    assume true = is_pid(ranch_listener_sup), "Failed to resume ranch socket acceptors. Ranch listener supervisor not found."
    ranch_acceptors_sup = CheckRanchAcceptors.ranch_acceptors_sup(ranch_listener_sup)
    assume true = is_pid(ranch_acceptors_sup), "Failed to resume ranch socket acceptors. Ranch acceptors supervisor not found."
    assume [_|_] = acceptors = CheckRanchAcceptors.ranch_acceptors(ranch_acceptors_sup), "Failed to suspend ranch socket acceptors. No acceptor processes found."
    acceptors_count = Enum.count(acceptors)
    info "Starting #{inspect acceptors_count} ranch socket acceptors..."
    assume true = Enum.all?(acceptors, fn acceptor ->
      case Supervisor.restart_child(ranch_acceptors_sup, acceptor) do
        {:ok, _child} -> true
        {:ok, _child, _term} -> true
        _ -> false
      end
    end), "Failed to start ranch socket acceptors."
    info "Resumed #{inspect acceptors_count} ranch acceptors."
  end

end
