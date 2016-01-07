defmodule Edeliver.Relup.Modification do
  @moduledoc """
    This module can be used to provide custom modification of
    relup instructions. By default the module

      Edeliver.Relup.DefaultModification

    is used to modify the relup instructions. There must exists
    only one implementation of that behaviour in your project.

    Example:

      defmodule Acme.Relup.Modification do
        use Edeliver.Relup.Modification

        def modify_relup(instructions = %Instructions{}, _config = %Config{}) do
          instructions |> Edeliver.Relup.DefaultModification.modify_relup(Config) # use default modifications
                       |> log_upgrade # add custom modifcation which logs the upgrade
        end

        defp log_upgrade(instructions = %Instructions{up_instructions: up_instructions}) do
          log_instruction = {apply, {:Elixir.Logger, info, [<<"Upgraded successfully">>]}}
          %{instructions| up_instructions: [log_instruction|up_instructions]}
        end
      end

  """
  use Behaviour

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Edeliver.Relup.Instruction
      alias Edeliver.Relup.Instructions
      alias ReleaseManager.Config
    end
  end


end