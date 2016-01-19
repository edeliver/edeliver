defmodule Edeliver.Relup.Instructions.CheckProcessesRunningOldCode do
  use Edeliver.Relup.RunnableInstruction

  def insert_where, do: &insert_before_point_of_no_return/2

  def run(_arguments) do
    Logger.info "Validating no process runs old code before upgrading..."
    modules = :erlang.loaded
    modules_running_old_code = Enum.filter(modules, fn(module) ->
      :erlang.check_old_code(module)
    end)
    if modules_running_old_code == [] do
      Logger.info "None of #{inspect Enum.count(modules)} runs old code."
    else
      throw {:error, {:running_old_code, modules_running_old_code}}
    end
  end

end
