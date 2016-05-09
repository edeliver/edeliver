defmodule Edeliver.Relup.PhoenixModification do
  @moduledoc """
    This module provides default modifications of the relup
    instructions for phoenix apps.
  """
  use Edeliver.Relup.Modification

  def modify_relup(instructions = %Instructions{}, config = %Config{}) do
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
  @spec usable?(ReleaseManager.Config.t) :: boolean
  def usable?(_config = %Config{}) do
    deps = Mix.Project.config[:deps]
    List.keymember?(deps, :phoenix, 0) && List.keymember?(deps, :phoenix_html, 0)
  end

  @doc """
    Returns the priority `Edeliver.Relup.Modification.priority_default/0` `+1`. Unless the module is set by the
    `RELUP_MODIFICATION_MODULE` env or the `--relup-mod=` command line option
    the module with the highest priority is used (which is also usable).
  """
  def priority, do: priority_default + 1

end