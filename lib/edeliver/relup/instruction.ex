defmodule Edeliver.Relup.Instruction do
  @moduledoc """
    This module can be used to provide custom instructions
    to modify the relup. They can be used the the implementation
    of the Edeliver.Relup.Modifcation module.

    Example:

      defmodule Acme.Relup.LogUpgradeInstruction do
        use Edeliver.Relup.Instruction

        def modify_relup(instructions = %Instructions{up_instructions: up_instructions}, _config = %Config{}) do
          log_instruction = {:apply, {:"Elixir.Logger", :info, [<<"Upgraded successfully">>]}}
          %{instructions| up_instructions: [log_instruction|up_instructions]}
        end

      end

      # using the instruction
      defmodule Acme.Relup.Modification do
        use Edeliver.Relup.Modification

        def modify_relup(instructions = %Instructions{}, _config = %Config{}) do
          instructions |> Edeliver.Relup.DefaultModification.modify_relup(Config) # use default modifications
                       |> Acme.Relup.LogUpgradeInstruction.modify_relup(Config) # apply also custom instructions
        end
      end

  """
  use Behaviour

  @callback modify_relup(Edeliver.Relup.Instructions.t, ReleaseManager.Config.t) :: Edeliver.Relup.Instructions.t

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Edeliver.Relup.Instruction
      alias Edeliver.Relup.Instructions
      alias ReleaseManager.Config

      @type instruction :: :relup.instruction
      @type instructions :: [instruction]

      @doc """
        Inserts an instruction or a list of instructions before the point of no return. All instructions
        running before that point of no return which fail will cause the upgrade to fail, while
        failing instructions running after that point will cause the node to restart the release.
      """
      @spec insert_before_point_of_no_return(%Instructions{}|instructions, new_instructions::instruction|instructions) :: updated_instructions::%Instructions{}|instructions
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
        Appends an instruction or a list of instructions to the list of other instructions.
      """
      @spec append(%Instructions{}|instructions, new_instructions::instruction|instructions) :: updated_instructions::%Instructions{}|instructions
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
        Inserts an instruction or a list of instructions before the given instruction.
      """
      @spec insert_before_instruction(%Instructions{}|instructions, new_instructions::instruction|instructions, before_instruction::instruction) :: updated_instructions::%Instructions{}|instructions
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
        Inserts an instruction or a list of instructions after the given instruction.
      """
      @spec insert_after_instruction(%Instructions{}|instructions, new_instructions::instruction|instructions, after_instruction::instruction) :: updated_instructions::%Instructions{}|instructions
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
        Ensures that the given module is loaded before the given instruction (if it needs to be loaded).
        If an `%Instructions{}` is given containing also the down instructions, it ensures that the module
        is unloaded after the instruction for the down instructions.
      """
      @spec ensure_module_loaded_before_instruction(%Instructions{}|instructions, instruction::instruction, module::atom) :: updated_instructions::%Instructions{}|instructions
      def ensure_module_loaded_before_instruction(instructions = %Instructions{}, instruction, module) do
        %{instructions|
          up_instructions:   ensure_module_loaded_before_instruction(instructions.up_instructions, instruction, module),
          down_instructions: ensure_module_unloaded_after_instruction(instructions.down_instructions, instruction, module)
        }
      end
      def ensure_module_loaded_before_instruction(up_instructions, instruction, module) when is_list(up_instructions) do
        ensure_module_loaded_before_instruction(up_instructions, instruction, module, [])
      end
      def ensure_module_loaded_before_instruction(instructions, instruction), do: ensure_module_loaded_before_instruction(instructions, instruction, __MODULE__)

      defp ensure_module_loaded_before_instruction(_instructions = [cur_instruction|rest], instruction, module, checked_instructions) do
        case cur_instruction do
          {:load_module, ^module} -> insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:load_module, ^module, _dep_mods} -> insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:load_module, ^module, _pre_purge, _post_purge, _dep_mods} -> insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:add_module,  ^module} -> insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:add_module,  ^module, _dep_mods} -> insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:load,       {^module, _pre_purge, _post_purge}} -> insert_before_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          _ -> ensure_module_loaded_before_instruction(rest, instruction, module, [cur_instruction|checked_instructions])
        end
      end
      defp ensure_module_loaded_before_instruction(_instructions = [], _instruction, _module, checked_instructions) do
        Enum.reverse(checked_instructions)
      end

      @doc """
        Ensures that the given module is (un)loaded after the given instruction (if it needs to be (un)loaded).
        If an `%Instructions{}` is given containing also the down instructions, it ensures that the module
        is (un)loaded before the instruction for the down instructions.
      """
      @spec ensure_module_unloaded_after_instruction(%Instructions{}|instructions, instruction::instruction, module::atom) :: updated_instructions::%Instructions{}|instructions
      def ensure_module_unloaded_after_instruction(instructions = %Instructions{}, instruction, module) do
        %{instructions|
          up_instructions:   ensure_module_unloaded_after_instruction(instructions.up_instructions, instruction, module),
          down_instructions: ensure_module_loaded_before_instruction(instructions.down_instructions, instruction, module)
        }
      end
      def ensure_module_unloaded_after_instruction(up_instructions, instruction, module) when is_list(up_instructions) do
        ensure_module_unloaded_after_instruction(up_instructions, instruction, module, [])
      end
      def ensure_module_unloaded_after_instruction(instructions, instruction), do: ensure_module_unloaded_after_instruction(instructions, instruction, __MODULE__)

      defp ensure_module_unloaded_after_instruction(_instructions = [cur_instruction|rest], instruction, module, checked_instructions) do
        case cur_instruction do
          {:load_module, ^module} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:load_module, ^module, _dep_mods} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:load_module, ^module, _pre_purge, _post_purge, _dep_mods} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:add_module,  ^module} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:add_module,  ^module, _dep_mods} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:load,       {^module, _pre_purge, _post_purge}} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:purge, [^module]} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:remove, {^module, _pre_purge, _post_purge}} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:delete_module, ^module} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          {:delete_module, ^module, _dep_mods} -> insert_after_instruction(Enum.reverse(checked_instructions) ++ rest, cur_instruction, instruction)
          _ -> ensure_module_unloaded_after_instruction(rest, instruction, module, [cur_instruction|checked_instructions])
        end
      end
      defp ensure_module_unloaded_after_instruction(_instructions = [], _instruction, _module, checked_instructions) do
        Enum.reverse(checked_instructions)
      end

    end
  end

end