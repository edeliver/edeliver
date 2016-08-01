defmodule Edeliver.Relup.Instructions.Info do
  @moduledoc """
    This upgrade instruction logs the given info
    message on the node which runs the upgrade

    and in the running upgrade script which was started
    by the `$APP/bin/$APP upgarde $RELEASE` command.
    Usage:

    ```
    Edeliver.Relup.Instructions.Info.modify_relup(config,
        _up_message="Synchronizing nodes",
        _down_message="Desynchronizing nodes",
        _insert_where = &append_after_point_of_no_return/2)`
    ```

    Available sections are:

    * `:check`    -> Checks whether upgrade is possible. Before "point of no return"
    * `:suspend`  -> Suspends processes before the upgrade. Right after the "point of no return"
    * `:upgrade`  -> Runs the upgrade by (un-)loading new(/old) code and updating processes and applications
    * `:resume`   -> Resumes processes after the upgrade that were suspended in the `:suspend` section.
    * `:finished` -> The upgrade finished successfully

  """
  use Edeliver.Relup.RunnableInstruction

  @spec modify_relup(instructions::Instructions.t, config::Edeliver.Relup.Config.t, up_message::String.t, down_message::String.t, insert_where::Instruction.insert_fun) :: Instructions.t
  def modify_relup(instructions = %Instructions{}, _config = %{}, up_message \\ "", down_message \\ "", insert_where_fun \\ &append_after_point_of_no_return/2) do
    up_instruction = call_this(up_message)
    down_instruction = call_this(down_message)
    %{instructions |
      up_instructions: insert_where_fun.(instructions.up_instructions, up_instruction)
                    |> ensure_module_loaded_before_first_runnable_instructions(up_instruction),
      down_instructions: insert_where_fun.(instructions.down_instructions, down_instruction)
                    |> ensure_module_unloaded_after_last_runnable_instruction(down_instruction)
    }
  end


  @doc """
    Logs the message on the node which is upgraded

    and in the upgrade script which was started by the
    `$APP/bin/$APP upgarde $RELEASE` command.
  """
  @spec run(message::String.t) :: :ok
  def run(message) do
    Logger.info message
    format_in_upgrade_script('~s~n', [String.to_char_list(message)])
  end
end
