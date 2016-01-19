defmodule Edeliver.Relup.RunnableInstruction do
  @moduledoc """
    This module can be used to provide custom instructions
    to modify the relup. They can be used the the implementation
    of the Edeliver.Relup.Modifcation module. A runnable instruction
    must implement a `run/1` function which will be executed
    during the upgrade on the nodes.

    Example:

      defmodule Acme.Relup.PingNodeInstruction do
        use Edeliver.Relup.RunnableInstruction

        def modify_relup(instructions = %Instructions{up_instructions: up_instructions}, _config = %Config{}) do
          node_name = :"node@host"
          %{instructions|
            up_instructions:   [call_this([node_name]) | instructions.up_instructions],
            down_instructions: [call_this([node_name]) | instructions.down_instructions]
          }
        end

        # executed during hot code upgrade from relup file
        def run(_options = [node_name]) do
          :net_adm.ping(node_name)
        end

        # actually implemented already in this module
        def call_this(arguments) do
          # creates a relup instruction to call `run/1` of this module
          {:apply, {__MODULE__, :run, arguments}}
        end

      end

      # using the instruction
      defmodule Acme.Relup.Modification do
        use Edeliver.Relup.Modification

        def modify_relup(instructions = %Instructions{}, _config = %Config{}) do
          instructions |> Edeliver.Relup.DefaultModification.modify_relup(Config) # use default modifications
                       |> Acme.Relup.PingNodeInstruction.modify_relup(Config) # apply also custom instructions
        end
      end

  """
  use Behaviour

  @doc """
    The function to run during hot code upgrade on nodes.
    If it returns an error before the `point_of_no_return` the
    upgrade is aborted. If it returns an error and was executed
    after that point, the release is restarted
  """
  @callback run(options::[term]) :: :ok | {:error, term}

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Edeliver.Relup.Instruction
      @behaviour Edeliver.Relup.RunnableInstruction
      alias Edeliver.Relup.Instructions
      alias ReleaseManager.Config
      require Logger

      @doc """
        Calls the `run/1` function of this module from the
        relup file during hot code upgrade
      """
      @spec call_this(arguments::[term]) :: instruction|instructions
      def call_this(arguments \\ []) do
        {:apply, {__MODULE__, :run, [arguments]}}
      end
    end
  end

end