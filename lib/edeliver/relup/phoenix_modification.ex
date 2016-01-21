defmodule Edeliver.Relup.PhoenixModification do
  @moduledoc """
    This module provides default modifications of the relup
    instructions for phoenix apps.
  """
  use Edeliver.Relup.Modification

  def modify_relup(instructions = %Instructions{}, config = %Config{}) do
    instructions
    # check whether upgrade is possible
    |> Edeliver.Relup.Instructions.CheckProcessesRunningOldCode.modify_relup(config)
    |> Edeliver.Relup.Instructions.CheckRanchAcceptors.modify_relup(config)
    # prepare the upgrade
    |> Edeliver.Relup.Instructions.SuspendRanchAcceptors.modify_relup(config)
    |> Edeliver.Relup.Instructions.SuspendChannels.modify_relup(config)
    |> Edeliver.Relup.Instructions.FinishRunningRequests.modify_relup(config)
    |> Edeliver.Relup.Instructions.SuspendDatabasePool.modify_relup(config)
    |> Edeliver.Relup.Instructions.FinishDatabaseQueries.modify_relup(config)
    # run the upgrade
    |> Edeliver.Relup.Instructions.SoftPurge.modify_relup(config)
    |> Edeliver.Relup.Instructions.SuspendAppProcesses.modify_relup(config)
    |> Edeliver.Relup.Instructions.ReloadModules.modify_relup(config)
    |> Edeliver.Relup.Instructions.CodeChangeOnAppProcesses.modify_relup(config)
    |> Edeliver.Relup.Instructions.ResumeAppProcesses.modify_relup(config)
    # resume
    |> Edeliver.Relup.Instructions.ResumeDatabasePool.modify_relup(config)
    |> Edeliver.Relup.Instructions.ResumeChannels.modify_relup(config)
    |> Edeliver.Relup.Instructions.ResumeRanchAcceptors.modify_relup(config)
  end

  @doc """
    Returns true if the current project is a phoenix project
  """
  @spec usable?(ReleaseManager.Config.t) :: boolean
  def usable?(_config = %Config{}) do
    deps = Mix.Project.config[:deps]
    List.keymember?(deps, :phoenix, 0) && List.keymember?(deps, :phoenix_html, 0)
  end

  def priority, do: priority_default + 1

end