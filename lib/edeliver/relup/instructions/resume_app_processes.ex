defmodule Edeliver.Relup.Instructions.ResumeAppProcesses do
  @moduledoc """
    This upgrade instruction does nothing

    but can be used in an `Edeliver.Relup.Modification` to indicate
    that the processes are resumed which use changed callback modules
    and were suspended by the `Edeliver.Relup.Instructions.SuspendAppProcesses`
    instruction.

    In a future step it might remove `resume` instructions from
    modules which does not change exported functions.
  """
  use Edeliver.Relup.Instruction

  def modify_relup(instructions = %Instructions{}, _config = %{}) do
    instructions
  end
end
