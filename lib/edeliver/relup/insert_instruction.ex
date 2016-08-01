defmodule Edeliver.Relup.InsertInstruction do
  @moduledoc """
    Provides functions to insert relup instructions at a given position

    which can be used in `Edeliver.Relup.Instruction` behaviour implementations
    in the relup file.
  """

  alias Edeliver.Relup.Instructions

  @doc """
    Inserts instruction(s) before the point of no return.

    All instructions running before that point of no return which fail will cause the
    upgrade to fail, while failing instructions running after that point will cause the
    node to restart the release.
  """
  @spec insert_before_point_of_no_return(Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions) :: updated_instructions::Instructions.t|Instructions.instructions
  def insert_before_point_of_no_return(instructions = %Instructions{}, new_instructions) do
    %{instructions|
      up_instructions:   insert_before_point_of_no_return(instructions.up_instructions,   new_instructions),
      down_instructions: insert_before_point_of_no_return(instructions.down_instructions, new_instructions)
    }
  end
  def insert_before_point_of_no_return(existing_instructions, new_instructions) do
    insert_before_instruction(existing_instructions, new_instructions, :point_of_no_return)
  end

  @doc """
    Inserts instruction(s) right after the point of no return.

    This means that it is the first instruction which should not fail, because the release
    handler will restart the release if any instruction fails after the point
    of no return.
  """
  @spec insert_after_point_of_no_return(Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions) :: updated_instructions::Instructions.t|Instructions.instructions
  def insert_after_point_of_no_return(instructions = %Instructions{}, new_instructions) do
    %{instructions|
      up_instructions:   insert_after_point_of_no_return(instructions.up_instructions,   new_instructions),
      down_instructions: insert_after_point_of_no_return(instructions.down_instructions, new_instructions)
    }
  end
  def insert_after_point_of_no_return(existing_instructions, new_instructions) do
    insert_after_instruction(existing_instructions, new_instructions, :point_of_no_return)
  end

  @doc """
    Inserts instruction(s) right after the last `load_object_code` instruction

    which is usually before the "point of no return" and one of the first instructions.
    This means that it is the first custom instruction which is executed. It is executed twice,
    once when checking whether the upgrade can be installed and once when the upgrade is installed.
  """
  @spec insert_after_load_object_code(Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions) :: updated_instructions::Instructions.t|Instructions.instructions
  def insert_after_load_object_code(instructions = %Instructions{}, new_instructions) do
    %{instructions|
      up_instructions:   insert_after_load_object_code(instructions.up_instructions,   new_instructions),
      down_instructions: insert_after_load_object_code(instructions.down_instructions, new_instructions)
    }
  end
  def insert_after_load_object_code(existing_instructions, new_instructions) do
    last_load_object_code_instruction = existing_instructions |> Enum.reverse |> List.keyfind(:load_object_code, 0)
    if last_load_object_code_instruction do
      insert_after_instruction(existing_instructions, new_instructions, last_load_object_code_instruction)
    else
      append(existing_instructions, new_instructions)
    end
  end

  @doc """
    Appends instruction(s) to the instruction after the "point of no return" but before any instruction

    which:

    - loads or unloads new code, which means before any
        `load_module`, `load`, `add_module`, `delete_module`,
        `remove`, `purge` instruction and
    - before any instruction which updates, starts or stops
      any running processes, which means before any
        `code_change`, `update`, `start`, `stop` instruction and
    - before any instruction which (re-)starts or stops
      any application or the emulator, which means before any
        `add_application`, `remove_application`, `restart_application`,
        `restart_emulator` and `restart_new_emulator` instruction.

    It does not consider load-instructions for `Edeliver.Relup.RunnableInstruction`s
    as code loading instructions for the release. They are inserted by the
    `RunnableInstruction` itself to ensure that the code of the runnable instruction
    is loaded before the instruction is executed. See `Edeliver.Relup.ShiftInstruction.ensure_module_loaded_before_instruction/3`.
  """
  @spec append_after_point_of_no_return(Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions) :: updated_instructions::Instructions.t|Instructions.instructions
  def append_after_point_of_no_return(instructions = %Instructions{}, new_instructions) do
    %{instructions|
      up_instructions:   append_after_point_of_no_return(instructions.up_instructions,  new_instructions),
      down_instructions: append_after_point_of_no_return(instructions.down_instructions, new_instructions)
    }
  end
  def append_after_point_of_no_return(existing_instructions, new_instruction) when is_list(existing_instructions) and not is_list(new_instruction) do
    append_after_point_of_no_return(existing_instructions, [new_instruction])
  end
  def append_after_point_of_no_return(existing_instructions, new_instructions) when is_list(existing_instructions) do
    append_after_point_of_no_return(existing_instructions, new_instructions, false, [])
  end

  defp append_after_point_of_no_return(_existing_instructions = [:point_of_no_return|rest], new_instructions, _after_point_of_no_return = false, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, true, [:point_of_no_return|instructions_before_instruction])
  end
  defp append_after_point_of_no_return(_existing_instructions = [instruction|rest], new_instructions, after_point_of_no_return = false, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [instruction|instructions_before_instruction])
  end
  # skip instructions which loads code and are inserted before a runnable instruction. see `Edeliver.Relup.RunnableInstruction`
  # and `Edeliver.Relup.Instruction.ensure_module_loaded_before_instruction/3`. That load instructions are inserted by the
  # `RunnableInstruction` itself and are not considered to be a 'real' code loading instruction for the running application.
  defp append_after_point_of_no_return(_existing_instructions = [load_runnable_instruction = {:load_module, module}, runnable_instruction = {:apply, {module, :run, _args}}|rest], new_instructions, after_point_of_no_return = true, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [runnable_instruction, load_runnable_instruction|instructions_before_instruction])
  end
  defp append_after_point_of_no_return(_existing_instructions = [load_runnable_instruction = {:load_module, module, _dep_mods}, runnable_instruction = {:apply, {module, :run, _args}}|rest], new_instructions, after_point_of_no_return = true, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [runnable_instruction, load_runnable_instruction|instructions_before_instruction])
  end
  defp append_after_point_of_no_return(_existing_instructions = [load_runnable_instruction = {:load_module, module, _pre_purge, _post_purge, _dep_mods}, runnable_instruction = {:apply, {module, :run, _args}}|rest], new_instructions, after_point_of_no_return = true, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [runnable_instruction, load_runnable_instruction|instructions_before_instruction])
  end
  defp append_after_point_of_no_return(_existing_instructions = [load_runnable_instruction = {:add_module, module}, runnable_instruction = {:apply, {module, :run, _args}}|rest], new_instructions, after_point_of_no_return = true, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [runnable_instruction, load_runnable_instruction|instructions_before_instruction])
  end
  defp append_after_point_of_no_return(_existing_instructions = [load_runnable_instruction = {:add_module, module, _dep_mods}, runnable_instruction = {:apply, {module, :run, _args}}|rest], new_instructions, after_point_of_no_return = true, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [runnable_instruction, load_runnable_instruction|instructions_before_instruction])
  end
  defp append_after_point_of_no_return(_existing_instructions = [load_runnable_instruction = {:load, {module, _pre_purge, _post_purge}}, runnable_instruction = {:apply, {module, :run, _args}}|rest], new_instructions, after_point_of_no_return = true, instructions_before_instruction) do
    append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [runnable_instruction, load_runnable_instruction|instructions_before_instruction])
  end
  # check whether the instruction is an instruction modifying code, processes or applications
  defp append_after_point_of_no_return(existing_instructions = [instruction|rest], new_instructions, after_point_of_no_return = true, instructions_before_instruction) do
    if modifies_code?(instruction) or modifies_processes?(instruction) or modifies_applications?(instruction) do
      Enum.reverse(instructions_before_instruction) ++ new_instructions ++ existing_instructions
    else
      append_after_point_of_no_return(rest, new_instructions, after_point_of_no_return, [instruction|instructions_before_instruction])
    end
  end
  defp append_after_point_of_no_return(_existing_instructions = [], new_instructions, _after_point_of_no_return, instructions_before_instruction) do
    Enum.reverse(instructions_before_instruction) ++ new_instructions
  end

  @doc """
    Appends instruction(s) to the list of other instructions.
  """
  @spec append(Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions) :: updated_instructions::Instructions.t|Instructions.instructions
  def append(instructions = %Instructions{}, new_instructions) do
    %{instructions|
      up_instructions:   append(instructions.up_instructions,  new_instructions),
      down_instructions: append(instructions.down_instructions, new_instructions)
    }
  end
  def append(existing_instructions, new_instruction) when is_list(existing_instructions) and not is_list(new_instruction) do
    append(existing_instructions, [new_instruction])
  end
  def append(existing_instructions, new_instructions) when is_list(existing_instructions) do
    existing_instructions ++ new_instructions
  end


  @doc """
    Inserts instruction(s) before the given instruction.
  """
  @spec insert_before_instruction(Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions, before_instruction::Instructions.instruction) :: updated_instructions::Instructions.t|Instructions.instructions
  def insert_before_instruction(instructions = %Instructions{}, new_instructions, before_instruction) do
    %{instructions|
      up_instructions:   insert_before_instruction(instructions.up_instructions,  new_instructions, before_instruction),
      down_instructions: insert_after_instruction(instructions.down_instructions, new_instructions, before_instruction)
    }
  end
  def insert_before_instruction(existing_instructions, new_instruction, before_instruction) when is_list(existing_instructions) and not is_list(new_instruction) do
    insert_before_instruction(existing_instructions, [new_instruction], before_instruction)
  end
  def insert_before_instruction(existing_instructions, new_instructions, before_instruction) when is_list(existing_instructions) do
    insert_before_instruction(existing_instructions, new_instructions, before_instruction, [])
  end

  defp insert_before_instruction(existing_instructions = [before_instruction|_], new_instructions, before_instruction, instructions_before_instruction) do
    Enum.reverse(instructions_before_instruction) ++ new_instructions ++ existing_instructions
  end
  defp insert_before_instruction(_existing_instructions = [no_point_of_no_return_instruction|rest], new_instructions, before_instruction, instructions_before_instruction) do
    insert_before_instruction(rest, new_instructions, before_instruction, [no_point_of_no_return_instruction|instructions_before_instruction])
  end
  defp insert_before_instruction(_existing_instructions = [], new_instructions, _before_instruction, instructions_before_instruction) do
    Enum.reverse(instructions_before_instruction) ++ new_instructions
  end


  @doc """
    Inserts instruction(s) after the given instruction.
  """
  @spec insert_after_instruction(Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions, after_instruction::Instructions.instruction) :: updated_instructions::Instructions.t|Instructions.instructions
  def insert_after_instruction(instructions = %Instructions{}, new_instructions, after_instruction) do
    %{instructions|
      up_instructions:   insert_after_instruction(instructions.up_instructions,  new_instructions, after_instruction),
      down_instructions: insert_before_instruction(instructions.down_instructions, new_instructions, after_instruction)
    }
  end
  def insert_after_instruction(existing_instructions, new_instruction, after_instruction) when is_list(existing_instructions) and not is_list(new_instruction) do
    insert_after_instruction(existing_instructions, [new_instruction], after_instruction)
  end
  def insert_after_instruction(existing_instructions, new_instructions, after_instruction) when is_list(existing_instructions) do
    insert_after_instruction(existing_instructions, new_instructions, after_instruction, [])
  end

  defp insert_after_instruction(_existing_instructions = [after_instruction|rest], new_instructions, after_instruction, instructions_before_instruction) do
    Enum.reverse(instructions_before_instruction) ++ [after_instruction|new_instructions] ++ rest
  end
  defp insert_after_instruction(_existing_instructions = [no_point_of_no_return_instruction|rest], new_instructions, after_instruction, instructions_before_instruction) do
    insert_after_instruction(rest, new_instructions, after_instruction, [no_point_of_no_return_instruction|instructions_before_instruction])
  end
  defp insert_after_instruction(_existing_instructions = [], new_instructions, _after_instruction, instructions_before_instruction) do
    Enum.reverse(instructions_before_instruction) ++ new_instructions
  end

  @doc """
    Returns true if the given instruction is an instruction which modifies an application

    by either (re-)starting or stopping it or by restarting the emulator. It returns
    `true` for the `add_application`, `remove_application`, `restart_new_emulator`
    and the `restart_emulator`, relup instructions.
  """
  @spec modifies_applications?(Instructions.instruction) :: boolean
  def modifies_applications?({:add_application, _application}), do: true
  def modifies_applications?({:add_application, _application, _type}), do: true
  def modifies_applications?({:remove_application, _application}), do: true
  def modifies_applications?({:restart_application, _application}), do: true
  def modifies_applications?(:restart_new_emulator), do: true
  def modifies_applications?(:restart_emulator), do: true
  def modifies_applications?(_), do: false

  @doc """
    Returns true if the given instruction is an instruction which modifies code

    by loading, unloading or purging it. It returns `true` for the `load_module`, `add_module`
    `delete_module`, `load`, `remove` and `purge` relup instructions.
  """
  @spec modifies_code?(Instructions.instruction) :: boolean
  def modifies_code?({:load_module, _module}), do: true
  def modifies_code?({:load_module, _module, _dep_mods}), do: true
  def modifies_code?({:load_module, _module, _pre_purge, _post_purge, _dep_mods}), do: true
  def modifies_code?({:add_module,  _module}), do: true
  def modifies_code?({:add_module,  _module, _dep_mods}), do: true
  def modifies_code?({:load,       {_module, _pre_purge, _post_purge}}), do: true
  def modifies_code?({:purge, [_module]}), do: true
  def modifies_code?({:remove, {_module, _pre_purge, _post_purge}}), do: true
  def modifies_code?({:delete_module, _module}), do: true
  def modifies_code?({:delete_module, _module, _dep_mods}), do: true
  def modifies_code?(_), do: false

  @doc """
    Returns true if the given instruction is an instruction which modifies any process

    by either by sending the  `code_change` sys event or by starting or stopping any
    process. It returns `true` for the `code_change`, `start`, `stop` and `update`
    relup instructions.
  """
  @spec modifies_processes?(Instructions.instruction) :: boolean
  def modifies_processes?({:update, _mod}), do: true
  def modifies_processes?({:update, _mod, :supervisor}), do: true
  def modifies_processes?({:update, _mod, _change_or_dep_mods}), do: true
  def modifies_processes?({:update, _mod, _change, _dep_mods}), do: true
  def modifies_processes?({:update, _mod, _change, _pre_purge, _post_purge, _dep_mods}), do: true
  def modifies_processes?({:update, _mod, Timeout, _change, _pre_purge, _post_purge, _dep_mods}), do: true
  def modifies_processes?({:update, _mod, ModType, Timeout, _change, _pre_purge, _post_purge, _dep_mods}), do: true
  def modifies_processes?({:code_change, [{_mod, _extra}]}), do: true
  def modifies_processes?({:code_change, _mode, [{_mod, _extra}]}), do: true
  def modifies_processes?({:start, [_mod]}), do: true
  def modifies_processes?({:stop, [_mod]}), do: true
  def modifies_processes?(_), do: false
end