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
      def insert_before_point_of_no_return(instructions = %Instructions{up_instructions: up_instructions, down_instructions: down_instructions}, new_instructions) do
        %{instructions|
          up_instructions:   insert_before_point_of_no_return(instructions.up_instructions,   new_instructions),
          down_instructions: insert_before_point_of_no_return(instructions.down_instructions, new_instructions)
        }
      end
      def insert_before_point_of_no_return(existing_instructions, new_instruction) when is_list(existing_instructions) and not is_list(new_instruction) do
        insert_before_point_of_no_return(existing_instructions, [new_instruction])
      end
      def insert_before_point_of_no_return(existing_instructions, new_instructions) when is_list(existing_instructions) do
        insert_before_point_of_no_return(existing_instructions, new_instructions, [])
      end

      defp insert_before_point_of_no_return(existing_instructions = [:point_of_no_return|_], new_instructions, instructions_before_point_of_no_return) do
        Enum.reverse(instructions_before_point_of_no_return) ++ new_instructions ++ existing_instructions
      end
      defp insert_before_point_of_no_return(_existing_instructions = [no_point_of_no_return_instruction|rest], new_instructions, instructions_before_point_of_no_return) do
        insert_before_point_of_no_return(rest, new_instructions, [no_point_of_no_return_instruction|instructions_before_point_of_no_return])
      end
      defp insert_before_point_of_no_return(_existing_instructions = [], new_instructions, instructions_before_point_of_no_return) do
        Enum.reverse(instructions_before_point_of_no_return) ++ new_instructions
      end
    end
  end

end