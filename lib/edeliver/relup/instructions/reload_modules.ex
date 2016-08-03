defmodule Edeliver.Relup.Instructions.ReloadModules do
  @moduledoc """
    This upgrade instruction does nothing

    but can be used in an `Edeliver.Relup.Modification` to indicate
    that the changed modules are reloaded at this part of the
    relup process.

    In a future step it might sort the modules to reload according
    to their dependencies.
  """
  use Edeliver.Relup.Instruction

  def modify_relup(instructions = %Instructions{}, _config = %{}) do
    instructions
  end
end
