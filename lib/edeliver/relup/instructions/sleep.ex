defmodule Edeliver.Relup.Instructions.Sleep do
  @moduledoc """
    This upgrade instruction is intended for testing only

    and just sleeps the given amount of seconds. This can
    be used to test instructions which suspend processes
    at the beginning of the upgrade before the new code is
    installed. Usage:

    ```
    Edeliver.Relup.Instructions.Sleep.modify_relup(config, _seconds = 30)
    ```

    It prints a countown in the upgrade script which was
    started by the `$APP/bin/$APP upgarde $RELEASE` command.
  """
  use Edeliver.Relup.RunnableInstruction

  @spec modify_relup(instructions::Instructions.t, config::Edeliver.Relup.Config.t, seconds::integer) :: Instructions.t
  def modify_relup(instructions = %Instructions{}, _config = %{}, seconds \\ 30) do
    call_this_instruction = call_this(max(0, seconds))
    insert_where_fun = insert_where()
    instructions |> insert_where_fun.(call_this_instruction)
                 |> ensure_module_loaded_before_instruction(call_this_instruction, __MODULE__)
  end

  @doc """
    Appends this instruction to the instructions after the "point of no return"

    but before any instruction which loads or unloads new code,
    (re-)starts or stops any running processes, or (re-)starts
    or stops any application or the emulator.
  """
  def insert_where, do: &append_after_point_of_no_return/2

  @doc """
    Waits the given amount of seconds and prints a countdown

    in the upgrade script which was started by the
    `$APP/bin/$APP upgarde $RELEASE` command.
  """
  @spec run(seconds::integer) :: :ok
  def run(seconds) do
    Logger.info "Waiting #{inspect seconds} seconds..."
    wait(seconds, seconds)
    Logger.info "Waited #{inspect seconds} seconds."
  end


  defp wait(_remaining_seconds = 0, seconds) do
    format_in_upgrade_script '\r---> Waited ~b seconds.                  ~n', [seconds]
  end
  defp wait(remaining_seconds, seconds) do
    format_in_upgrade_script '\r---> Waiting ~b seconds...               ', [remaining_seconds]
    receive do
    after 1000 ->  wait(remaining_seconds - 1, seconds)
    end
  end


end
