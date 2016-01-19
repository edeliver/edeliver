defmodule Edeliver.Relup.Instructions.CheckProcessesRunningOldCode do
  use Edeliver.Relup.RunnableInstruction

  def modify_relup(instructions = %Instructions{}, _config = %Config{}) do
    instructions |> insert_before_point_of_no_return(call_this)
  end

  def run(_arguments) do
    Logger.info "Validating no process runs old code before upgrading..."
  end
end
