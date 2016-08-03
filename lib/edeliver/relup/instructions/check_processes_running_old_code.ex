defmodule Edeliver.Relup.Instructions.CheckProcessesRunningOldCode do
  @moduledoc """
    Cancels the upgrade if there are processes running old code

    from previous upgrades. This upgrade instruction checks whether any of the
    modules that will be (re)loaded during upgrade has old code.
    If any of them has old code it will throw an error and abort the release upgrade.
    This prevents  crashing and restarting the node during the live upgrade. This instruction
    is insterted before the "point of no return" which causes it to run twice,
    once when checking the relup and once when executing the relup.
  """
  use Edeliver.Relup.RunnableInstruction

  @doc """
    Inserts the instruction before the point of no return.

    This causes the release handler to abort the upgrade
    already when running `:release_handler.check_install_release/1`
    if this instruction fails.
  """
  def insert_where, do: &insert_before_point_of_no_return/2

  @doc """
    Returns the modules which will be loaded during the upgrade.

    These modules are taken as argument for the `run/1` function and only
    these modules are checked whether they run old code. Modules which
    will not be updated during the upgrade does not affect the upgrade
    process even if they run old code. The modules to check are take from
    the `load_object_code` instructions.
  """
  def arguments(instructions = %Instructions{}, _config = %{}) do
    modules_from_load_object_code_instructions(instructions.up_instructions, [])
  end

  @doc """
    Checks whether the modules passed as argument have old code.

    These modules are the modules which will be upgraded. This function runs
    twice because it is executed before the "point of no return", once when checking the
    relup and once when executing the relup.
  """
  def run(modules) do
    info "Validating no process runs old code before upgrading..."
    modules_running_old_code = Enum.filter(modules, fn(module) ->
      :erlang.check_old_code(module)
    end)
    if modules_running_old_code == [] do
      info "None of #{inspect Enum.count(modules)} modules have old code."
    else
      throw {:error, {:running_old_code, modules_running_old_code}}
    end
  end

  defp modules_from_load_object_code_instructions([{:load_object_code, {_app, _vsn, modules_to_load = [_|_]}}|rest], modules) do
    modules_from_load_object_code_instructions(rest, modules ++ modules_to_load)
  end
  defp modules_from_load_object_code_instructions([_|rest], modules) do
    modules_from_load_object_code_instructions(rest, modules)
  end
  defp modules_from_load_object_code_instructions([], modules), do: modules

end
