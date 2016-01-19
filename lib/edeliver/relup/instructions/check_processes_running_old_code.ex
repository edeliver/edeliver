defmodule Edeliver.Relup.Instructions.CheckProcessesRunningOldCode do
  use Edeliver.Relup.RunnableInstruction

  def insert_where, do: &insert_before_point_of_no_return/2

  def run(_arguments) do
    Logger.info "Validating no process runs old code before upgrading..."
  end

end
