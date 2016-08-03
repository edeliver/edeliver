defmodule Edeliver.Relup.Instructions.SuspendAppProcesses do
  @moduledoc """
    This upgrade instruction does nothing

    but can be used in an `Edeliver.Relup.Modification` to indicate
    that the processes are suspended which use changed callback modules
    See also `Edeliver.Relup.Instructions.ResumeAppProcesses`.

    In a future step it might remove `suspend` instructions from
    modules which does not change exported functions and / or
    group the suspending of the processes in that way, that
    first all processes are suspended, then all code-changed
    and in the end resumed instead of performing this steps
    per module.
  """
  use Edeliver.Relup.Instruction

  def modify_relup(instructions = %Instructions{}, _config = %{}) do
    instructions
  end
end
