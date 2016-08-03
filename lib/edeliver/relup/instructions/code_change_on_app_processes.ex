defmodule Edeliver.Relup.Instructions.CodeChangeOnAppProcesses do
  @moduledoc """
    This upgrade instruction does nothing

    but can be used in an `Edeliver.Relup.Modification` to indicate
    that the `code_change` function is invoked for suspended modules
    which changed. See `Edeliver.Relup.Instructions.SuspendAppProcesses`.

    In a future step it might remove `code_change` instructions from
    modules which does not change exported functions.
  """
  use Edeliver.Relup.Instruction

  def modify_relup(instructions = %Instructions{}, _config = %{}) do
    instructions
  end
end
