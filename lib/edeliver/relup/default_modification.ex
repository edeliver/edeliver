defmodule Edeliver.Relup.DefaultModification do
  @moduledoc """
    This module provides default modifications of the relup instructions.

    It is used unless a `Edeliver.Relup.Modification`
    module is found with a higher priority (and which is also
    usable) or another module is passed to the `--relup-mod=`
    command line option. E.g. for phoenix apps this would be the
    default `Edeliver.Relup.PhoenixModification`.
    This module uses the `Edeliver.Relup.Instructions.SoftPurge`
    instruction to replace `:brutal_purge` code loading options
    with `:soft_purge`.
  """
  use Edeliver.Relup.Modification

  def modify_relup(instructions = %Instructions{}, config = %{}) do
    instructions |> Edeliver.Relup.Instructions.SoftPurge.modify_relup(config)
  end

  @doc """
    Returns the priority `Edeliver.Relup.Modification.priority_default/0`.

    Unless the module is set by the `RELUP_MODIFICATION_MODULE` env or
    the `--relup-mod=` command line option the module with the highest priority
    is used (which is also usable).
  """
  def priority, do: priority_default()

end