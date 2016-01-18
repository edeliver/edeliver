defmodule Edeliver.Relup.PhoenixModification do
  @moduledoc """
    This module provides default modifications of the relup
    instructions for phoenix apps.
  """
  use Edeliver.Relup.Modification

  def modify_relup(instructions = %Instructions{}, config = %Config{}) do
    instructions |> Edeliver.Relup.Instructions.SoftPurge.modify_relup(config)
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