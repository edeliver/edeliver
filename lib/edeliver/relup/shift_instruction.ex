defmodule Edeliver.Relup.ShiftInstruction do
  @moduledoc """
    Provides functions to move relup instructions to a given position

    which can be used in `Edeliver.Relup.Instruction` behaviour implementations
    in the relup file to fulfill some requirements.
  """

  alias Edeliver.Relup.Instructions
  alias Edeliver.Relup.InsertInstruction

  @doc """
    Ensures that the given module is loaded before the given instruction (if it needs to be loaded).

    If an `%Edeliver.Relup.Instructions{}` is given containing also the down instructions, it ensures that the module
    is unloaded after the instruction for the down instructions.
    Use this function only, if the instruction should be used only once in a `Relup.Modification` for
    the up or down instructions. Use the `ensure_module_loaded_before_first_runnable_instructions/2` function
    instead if the `RunnableInstruction` can be used several times in a `Relup.Modification`.
  """
  @spec ensure_module_loaded_before_instruction(Instructions.t|Instructions.instructions, instruction::Instructions.instruction, module::module) :: updated_instructions::Instructions.t|Instructions.instructions
  def ensure_module_loaded_before_instruction(instructions = %Instructions{}, instruction, module) do
    %{instructions|
      up_instructions:   ensure_module_loaded_before_instruction(instructions.up_instructions, instruction, module),
      down_instructions: ensure_module_unloaded_after_instruction(instructions.down_instructions, instruction, module)
    }
  end
  def ensure_module_loaded_before_instruction(up_instructions, instruction, module) when is_list(up_instructions) do
    ensure_module_loaded_before_instruction(up_instructions, instruction, module, _found_instruction = false, [])
  end

  defp ensure_module_loaded_before_instruction(_instructions = [instruction|rest], instruction, module, _found_instruction = false, checked_instructions) do
    ensure_module_loaded_before_instruction(rest, instruction, module, _found_instruction = true, [instruction|checked_instructions])
  end
  defp ensure_module_loaded_before_instruction(instructions = [cur_instruction|rest], instruction, module, found_instruction, checked_instructions) do
    found_load_instruction = case cur_instruction do
      {:load_module, ^module} -> true
      {:load_module, ^module, _dep_mods} -> true
      {:load_module, ^module, _pre_purge, _post_purge, _dep_mods} -> true
      {:add_module,  ^module} -> true
      {:add_module,  ^module, _dep_mods} -> true
      {:load,       {^module, _pre_purge, _post_purge}} -> true
      _ -> false
    end
    cond do
      found_load_instruction and found_instruction -> InsertInstruction.insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
      found_load_instruction and not found_instruction -> Enum.reverse(checked_instructions) ++ instructions # load instruction is already before given instruction
      true -> ensure_module_loaded_before_instruction(rest, instruction, module, found_instruction, [cur_instruction|checked_instructions])
    end
  end
  defp ensure_module_loaded_before_instruction(_instructions = [], _instruction, _module, _found_instruction, checked_instructions) do
    Enum.reverse(checked_instructions)
  end

  @doc """
    Ensures that the given module is loaded before the first occurrence of the runnable instruction.

    If an `%Edeliver.Relup.Instructions{}` is given containing also the down instructions, it ensures that the module
    is unloaded after the last occurrence of the runnable down instruction. Use this function instead of the
    `ensure_module_loaded_before_instruction/3` function if the `Edeliver.Relup.RunnableInstruction` can be used several times
    in a `Edeliver.Relup.Modification`. If the module did not change and was already included into the old release this function
    has no effect.
  """
  @spec ensure_module_loaded_before_first_runnable_instructions(Instructions.t|Instructions.instructions, runnable_instruction::{:apply, {module::module, :run, arguments::[term]}}, module::module) :: updated_instructions::Instructions.t|Instructions.instructions
  def ensure_module_loaded_before_first_runnable_instructions(instructions = %Instructions{}, runnable_instruction, module) do
    %{instructions|
      up_instructions:   ensure_module_loaded_before_first_runnable_instructions(instructions.up_instructions, runnable_instruction, module),
      down_instructions: ensure_module_unloaded_after_last_runnable_instruction(instructions.down_instructions, runnable_instruction, module)
    }
  end
  def ensure_module_loaded_before_first_runnable_instructions(up_instructions, runnable_instruction, module) when is_list(up_instructions) do
    ensure_module_loaded_before_first_runnable_instructions(up_instructions, runnable_instruction, _found_instruction = false, module, [])
  end

  @doc """
    Ensures that the module of `Edeliver.Relup.RunnableInstruction` is loaded before it is executed.

    E.g. if an `Edeliver.Relup.Instructions.Info` instruction implements the behaviour
    `Edeliver.Relup.RunnableInstruction` it creates and inserts a:
    ```elixir
    {:apply, {Elixir.Edeliver.Relup.Instructions.Info, :run, ["hello"]}}
    ```
    [relup](http://www.erlang.org/doc/man/relup.html) instruction. This function ensures that the instruction which loads
    that module is placed before that instruction. This is essential if the `Edeliver.Relup.RunnableInstruction` is new
    and was not included into the old version of the release or has changed in the new version.
  """
  @spec ensure_module_loaded_before_first_runnable_instructions(Instructions.t|Instructions.instructions, runnable_instruction::{:apply, {module::module, :run, arguments::[term]}}) :: updated_instructions::Instructions.t|Instructions.instructions
  def ensure_module_loaded_before_first_runnable_instructions(instructions, runnable_instruction = {:apply, {module, :run, _arguments}}) do
    ensure_module_loaded_before_first_runnable_instructions(instructions, runnable_instruction, module)
  end

  defp ensure_module_loaded_before_first_runnable_instructions(_instructions = [runnable_instruction|rest], runnable_instruction, _found_instruction = false, module, checked_instructions) do
    ensure_module_loaded_before_first_runnable_instructions(rest, runnable_instruction, _found_instruction = true, module, [runnable_instruction|checked_instructions])
  end
  defp ensure_module_loaded_before_first_runnable_instructions(instructions = [cur_instruction|rest], runnable_instruction = {:apply, {instruction_module, :run, _arguments}}, found_instruction, module, checked_instructions) do
    found_load_instruction = case cur_instruction do
      {:load_module, ^module} -> true
      {:load_module, ^module, _dep_mods} -> true
      {:load_module, ^module, _pre_purge, _post_purge, _dep_mods} -> true
      {:add_module,  ^module} -> true
      {:add_module,  ^module, _dep_mods} -> true
      {:load,       {^module, _pre_purge, _post_purge}} -> true
      _ -> false
    end
    cond do
      found_load_instruction and found_instruction ->
        first_runnable_instruction = first_runnable_instruction(Enum.reverse(checked_instructions) ++ instructions ++ [runnable_instruction], instruction_module)
        InsertInstruction.insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, first_runnable_instruction)
      found_load_instruction and not found_instruction ->
        Enum.reverse(checked_instructions) ++ instructions # load instruction is already before given runnable instruction
      true ->
        ensure_module_loaded_before_first_runnable_instructions(rest, runnable_instruction, found_instruction, module, [cur_instruction|checked_instructions])
    end
  end
  defp ensure_module_loaded_before_first_runnable_instructions(_instructions = [], _runnable_instruction, _found_instruction, _module, checked_instructions) do
    Enum.reverse(checked_instructions)
  end

  @doc """
    Returns the first occurence of a `RunnableInstruction` implemented by the given module.
  """
  @spec first_runnable_instruction(instructions::Instructions.instructions, module::module) :: runnable_instruction::{:apply, {module::module, :run, arguments::[term]}} | :not_found
  def first_runnable_instruction(_instructions = [], _module), do: :not_found
  def first_runnable_instruction(_instructions = [runnable_instruction = {:apply, {module, :run, _arguments}}|_], module) do
    runnable_instruction
  end
  def first_runnable_instruction(_instructions = [_|rest], module) do
    first_runnable_instruction(rest, module)
  end

  @doc """
    Ensures that the given module is (un)loaded after the given instruction (if it needs to be (un)loaded).

    If an `%Edeliver.Relup.Instructions{}` is given containing also the down instructions, it ensures that the module
    is (un)loaded before the instruction for the down instructions.
    Use this function only, if the instruction should be used only once in a `Relup.Modification` for
    the up or down instructions. Use the `ensure_module_unloaded_after_last_runnable_instruction/2` function
    instead if the `RunnableInstruction` can be used several times in a `Relup.Modification`.
  """
  @spec ensure_module_unloaded_after_instruction(Instructions.t|Instructions.instructions, instruction::Instructions.instruction, module::module) :: updated_instructions::Instructions.t|Instructions.instructions
  def ensure_module_unloaded_after_instruction(instructions = %Instructions{}, instruction, module) do
    %{instructions|
      up_instructions:   ensure_module_unloaded_after_instruction(instructions.up_instructions, instruction, module),
      down_instructions: ensure_module_loaded_before_instruction(instructions.down_instructions, instruction, module)
    }
  end
  def ensure_module_unloaded_after_instruction(up_instructions, instruction, module) when is_list(up_instructions) do
    ensure_module_unloaded_after_instruction(up_instructions, instruction, module, [])
  end
  defp ensure_module_unloaded_after_instruction(instructions = [instruction|_rest], instruction, _module, checked_instructions) do
    Enum.reverse(checked_instructions) ++ instructions # don't need to check instructions after instruction
  end
  defp ensure_module_unloaded_after_instruction(_instructions = [cur_instruction|rest], instruction, module, checked_instructions) do
    found_unload_instruction = case cur_instruction do
      {:load_module, ^module} -> true
      {:load_module, ^module, _dep_mods} -> true
      {:load_module, ^module, _pre_purge, _post_purge, _dep_mods} -> true
      {:add_module,  ^module} -> true
      {:add_module,  ^module, _dep_mods} -> true
      {:load,       {^module, _pre_purge, _post_purge}} -> true
      {:remove, {^module, _pre_purge, _post_purge}} -> true
      {:delete_module, ^module} -> true
      {:delete_module, ^module, _dep_mods} -> true
      {:purge, [^module]} -> true
      _ -> false
    end
    if found_unload_instruction do
      InsertInstruction.insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
      |> ensure_module_unloaded_after_instruction(instruction, module, []) # continue finding unload instructions before
    else
      ensure_module_unloaded_after_instruction(rest, instruction, module, [cur_instruction|checked_instructions])
    end
  end
  defp ensure_module_unloaded_after_instruction(_instructions = [], _instruction, _module, checked_instructions) do
    Enum.reverse(checked_instructions)
  end

  @doc """
    Ensures that the given module is (un)loaded after the last occurrenct of the given runnable instruction.

    If an `%Edeliver.Relup.Instructions{}` is given containing also the down instructions, it ensures that the module
    is loaded before the first occurrence of the runnable instruction for the down instructions.
    Use this function instead of the `ensure_module_unloaded_after_instruction/3` function if the `RunnableInstruction`
    can be used several times  in a `Relup.Modification`.
  """
  @spec ensure_module_unloaded_after_last_runnable_instruction(Instructions.t|Instructions.instructions, runnable_instruction::{:apply, {module::module, :run, arguments::[term]}}, module::module) :: updated_instructions::Instructions.t|Instruction.instructions
  def ensure_module_unloaded_after_last_runnable_instruction(instructions = %Instructions{}, runnable_instruction, module) do
    %{instructions|
      up_instructions:   ensure_module_unloaded_after_last_runnable_instruction(instructions.up_instructions, runnable_instruction, module),
      down_instructions: ensure_module_loaded_before_first_runnable_instructions(instructions.down_instructions, runnable_instruction, module)
    }
  end
  def ensure_module_unloaded_after_last_runnable_instruction(up_instructions, runnable_instruction, module) when is_list(up_instructions) do
    ensure_module_unloaded_after_last_runnable_instruction(up_instructions, runnable_instruction, module, [])
  end

  @doc """
    Ensures that the module of `Edeliver.Relup.RunnableInstruction` is unloaded after it was executed.

    E.g. if an `Edeliver.Relup.Instructions.Info` instruction implements the behaviour `Edeliver.Relup.RunnableInstruction`
    it creates and inserts a
    ```elixir
    {:apply, {Elixir.Edeliver.Relup.Instructions.Info, :run, ["hello"]}}
    ```
    [relup](http://www.erlang.org/doc/man/relup.html)  instruction. This function ensures that the instruction
    which unloads that module is placed after that instruction. This is essential if the `Edeliver.Relup.RunnableInstruction`
    was changed and the new version is unloaded in the downgrade instructions.
  """
  def ensure_module_unloaded_after_last_runnable_instruction(instructions, runnable_instruction = {:apply, {module, :run, _arguments}}) do
    ensure_module_unloaded_after_last_runnable_instruction(instructions, runnable_instruction, module)
  end

  defp ensure_module_unloaded_after_last_runnable_instruction(instructions = [runnable_instruction|_rest], runnable_instruction, _module, checked_instructions) do
    Enum.reverse(checked_instructions) ++ instructions # don't need to check instructions after instruction
  end
  defp ensure_module_unloaded_after_last_runnable_instruction(instructions = [cur_instruction|rest], runnable_instruction = {:apply, {instruction_module, :run, _arguments}}, module, checked_instructions) do
    found_unload_instruction = case cur_instruction do
      {:load_module, ^module} -> true
      {:load_module, ^module, _dep_mods} -> true
      {:load_module, ^module, _pre_purge, _post_purge, _dep_mods} -> true
      {:add_module,  ^module} -> true
      {:add_module,  ^module, _dep_mods} -> true
      {:load,       {^module, _pre_purge, _post_purge}} -> true
      {:remove, {^module, _pre_purge, _post_purge}} -> true
      {:delete_module, ^module} -> true
      {:delete_module, ^module, _dep_mods} -> true
      {:purge, [^module]} -> true
      _ -> false
    end
    if found_unload_instruction do
      last_runnable_instruction = first_runnable_instruction(Enum.reverse(Enum.reverse(checked_instructions) ++ instructions ++ [runnable_instruction]), instruction_module)
      InsertInstruction.insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, last_runnable_instruction)
      |> ensure_module_unloaded_after_last_runnable_instruction(runnable_instruction, module, []) # continue finding unload instructions before
    else
      ensure_module_unloaded_after_last_runnable_instruction(rest, runnable_instruction, module, [cur_instruction|checked_instructions])
    end
  end
  defp ensure_module_unloaded_after_last_runnable_instruction(_instructions = [], _runnable_instruction, _module, checked_instructions) do
    Enum.reverse(checked_instructions)
  end


end