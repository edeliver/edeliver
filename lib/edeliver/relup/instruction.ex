defmodule Edeliver.Relup.Instruction do
  @moduledoc """
    This module can be used to provide custom instructions
    to modify the relup. They can be used the the implementation
    of the Edeliver.Relup.Modifcation module.

    Example:

      defmodule Acme.Relup.LogUpgradeInstruction do
        use Edeliver.Relup.Instruction

        def modify_relup(instructions = %Instructions{up_instructions: up_instructions}, _config = %Config{}) do
          log_instruction = {apply, {:Elixir.Logger, info, [<<"Upgraded successfully">>]}}
          %{instructions| up_instructions: [log_instruction|up_instructions]}
        end

      end

      # using the instruciton
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
    end
  end

end