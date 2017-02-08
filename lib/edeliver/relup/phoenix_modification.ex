defmodule Edeliver.Relup.PhoenixModification do
  @moduledoc """
    This module provides default modifications of the relup instructions for phoenix apps.

    It performs the following steps:

    - __Checking whether the upgrade is possible__

      - by checking whether there are processes running old code (from a previous upgrade)
      - by checking whether the ranch acceptor processes can be found
      - by checking whether ranch connection processes can be found

      or canceling the upgrade if one of the checks fails.

    - __Preparing the upgrade__

      - by suspending all ranch acceptors to avoid accepting new connections / requests during the hot code upgrade
      - by suspending phoenix channels
      - by waiting a short time until running requests are finished and notifying the remaining that an upgrades starts (this allows to rerun failed requests later)

    - __Executing the upgrade__

      - by using `:soft_purge` instead of `:brutal_purge` when loading new code
      - by suspending all processes running code of changed modules
      - by calling `code_change` at this processes
      - by resuming that processes

    - __Finishing the upgrade__

      - by rerunning requests that failed during the upgrade
      - by resuming all phoenix channels
      - by resuming all ranch acceptors to continue accepting new connections

  """
  use Edeliver.Relup.Modification

  def modify_relup(instructions = %Instructions{}, config = %{}) do
    instructions
    # check whether upgrade is possible
    |> Edeliver.Relup.Instructions.StartSection.modify_relup(config, :check)
    |> Edeliver.Relup.Instructions.CheckProcessesRunningOldCode.modify_relup(config)
    |> Edeliver.Relup.Instructions.CheckRanchAcceptors.modify_relup(config)
    |> Edeliver.Relup.Instructions.CheckRanchConnections.modify_relup(config)
    # prepare the upgrade
    |> Edeliver.Relup.Instructions.StartSection.modify_relup(config, :suspend)
    |> Edeliver.Relup.Instructions.SuspendRanchAcceptors.modify_relup(config)
    |> Edeliver.Relup.Instructions.SuspendChannels.modify_relup(config)
    |> Edeliver.Relup.Instructions.FinishRunningRequests.modify_relup(config)
    # run the upgrade
    |> Edeliver.Relup.Instructions.StartSection.modify_relup(config, :upgrade)
    |> Edeliver.Relup.Instructions.SoftPurge.modify_relup(config)
    |> Edeliver.Relup.Instructions.SuspendAppProcesses.modify_relup(config)
    |> Edeliver.Relup.Instructions.ReloadModules.modify_relup(config)
    |> Edeliver.Relup.Instructions.CodeChangeOnAppProcesses.modify_relup(config)
    |> Edeliver.Relup.Instructions.ResumeAppProcesses.modify_relup(config)
    # resume
    |> Edeliver.Relup.Instructions.StartSection.modify_relup(config, :resume)
    |> Edeliver.Relup.Instructions.RerunFailedRequests.modify_relup(config)
    |> Edeliver.Relup.Instructions.ResumeChannels.modify_relup(config)
    |> Edeliver.Relup.Instructions.ResumeRanchAcceptors.modify_relup(config)
    |> Edeliver.Relup.Instructions.StartSection.modify_relup(config, :finished)
  end

  @doc """
    Returns true if the current project is a phoenix project
  """
  @spec usable?(Edeliver.Relup.Config.t) :: boolean
  def usable?(_config = %{}) do
    deps = Mix.Project.config[:deps]
    List.keymember?(deps, :phoenix, 0) && List.keymember?(deps, :phoenix_html, 0)
  end

  @doc """
    Returns the priority `Edeliver.Relup.Modification.priority_default/0` `+1`.

    Unless the module is set by the `RELUP_MODIFICATION_MODULE` env or
    the `--relup-mod=` command line option the module with the highest priority
    is used (which is also usable).
  """
  def priority, do: priority_default() + 1

end