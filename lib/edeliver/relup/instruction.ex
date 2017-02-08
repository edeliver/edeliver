defmodule Edeliver.Relup.Instruction do
  @moduledoc """
    This behaviour can be used to provide custom instructions to modify the relup.

    They can be used in the implementations of
    of the `Edeliver.Relup.Modifcation` behaviour.

    Example:

      defmodule Acme.Relup.LogUpgradeInstruction do
        use Edeliver.Relup.Instruction

        def modify_relup(instructions = %Instructions{up_instructions: up_instructions}, _config = %{}) do
          log_instruction = {:apply, {:"Elixir.Logger", :info, [<<"Upgraded successfully">>]}}
          %{instructions| up_instructions: [log_instruction|up_instructions]}
        end

      end

      # using the instruction
      defmodule Acme.Relup.Modification do
        use Edeliver.Relup.Modification

        def modify_relup(instructions = %Instructions{}, config = %{}) do
          instructions |> Edeliver.Relup.DefaultModification.modify_relup(config) # use default modifications
                       |> Acme.Relup.LogUpgradeInstruction.modify_relup(config) # apply also custom instructions
        end
      end

    edeliver already provides a set of relup instructions:

    * `Edeliver.Relup.Instructions.CheckProcessesRunningOldCode`
    * `Edeliver.Relup.Instructions.CheckRanchAcceptors`
    * `Edeliver.Relup.Instructions.CheckRanchConnections`
    * `Edeliver.Relup.Instructions.CodeChangeOnAppProcesses`
    * `Edeliver.Relup.Instructions.FinishRunningRequests`
    * `Edeliver.Relup.Instructions.Info`
    * `Edeliver.Relup.Instructions.ReloadModules`
    * `Edeliver.Relup.Instructions.RerunFailedRequests`
    * `Edeliver.Relup.Instructions.ResumeAppProcesses`
    * `Edeliver.Relup.Instructions.ResumeChannels`
    * `Edeliver.Relup.Instructions.ResumeRanchAcceptors`
    * `Edeliver.Relup.Instructions.Sleep`
    * `Edeliver.Relup.Instructions.SoftPurge`
    * `Edeliver.Relup.Instructions.StartSection`
    * `Edeliver.Relup.Instructions.SuspendAppProcesses`
    * `Edeliver.Relup.Instructions.SuspendChannels`
    * `Edeliver.Relup.Instructions.SuspendRanchAcceptors`


  """

  alias Edeliver.Relup.Instructions

  @typedoc """
    A function that inserts a new instruction or a set of new instructions
    at a given place in the list of existing instructions. For most
    [appup instructions](http://erlang.org/doc/man/appup.html) from the `relup` file
    it matters when they will be executed, e.g before or after some other instructions.
  """
  @type insert_fun :: ((Instructions.t|Instructions.instructions, new_instructions::Instructions.instruction|Instructions.instructions) -> updated_instructions::Instructions.t|Instructinos.instructions)

  @doc """
    Modifies the relup file.

    Modifies the `relup` file which will be used to upgrade (or downgrade) from one version to another
    by inserting, removing, or shifting [appup instructions](http://erlang.org/doc/man/appup.html).
    See `Edeliver.Relup.InsertInstruction` and `Edeliver.Relup.ShiftInstruction` for useful helpers to
    insert / position the instructions and `Edeliver.Relup.RunnableInstruction` to execute custom code
    during the upgrade.
  """
  @callback modify_relup(Edeliver.Relup.Instructions.t, Edeliver.Relup.Config.t) :: Edeliver.Relup.Instructions.t

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Edeliver.Relup.Instruction
      alias Edeliver.Relup.Instructions
      import Edeliver.Relup.InsertInstruction
      import Edeliver.Relup.ShiftInstruction
    end
  end

end