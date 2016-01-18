defmodule Edeliver.Relup.Instructions.ReloadModules do
  use Edeliver.Relup.Instruction

  def modify_relup(instructions = %Instructions{}, _config = %Config{}) do
    instructions
  end
end
