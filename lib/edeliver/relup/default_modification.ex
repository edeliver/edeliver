defmodule Edeliver.Relup.DefaultModification do
  @moduledoc """
    This module provides default modifications of the relup
    instructions.
  """
  use Edeliver.Relup.Modification

  def modify_relup(instructions = %Instructions{}, config = %Config{}) do
    instructions |> Edeliver.Relup.Instructions.SoftPurge.modify_relup(config)
  end
end