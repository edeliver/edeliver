defmodule Edeliver.Relup.Instructions.CheckProcessesRunningOldCode do
  use Edeliver.Relup.RunnableInstruction

  def modify_relup(instructions = %Instructions{}, _config = %Config{}) do
    call_this_instruction = call_this
    instructions |> insert_before_point_of_no_return(call_this_instruction)
                 |> ensure_module_loaded_before_instruction(call_this_instruction)
  end

  def run(_arguments) do
    Logger.info "Validating no process runs old code before upgrading..."
  end

end
