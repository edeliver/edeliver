defmodule Edeliver.Relup.Instructions.SuspendAppProcesses do
  use Edeliver.Relup.Instruction

  def modify_relup(instructions = %Instructions{}, _config = %Config{}) do
    instructions
  end
end
