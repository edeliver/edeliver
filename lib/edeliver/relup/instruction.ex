defmodule Edeliver.Relup.Instruction do
  @moduledoc """
    This behaviour can be used to provide custom instructions to modify the relup.

    They can be used in the implementations of
    of the `Edeliver.Relup.Modifcation` behaviour.

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
  use Behaviour

  @callback modify_relup(Edeliver.Relup.Instructions.t, ReleaseManager.Config.t) :: Edeliver.Relup.Instructions.t

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Edeliver.Relup.Instruction
      alias Edeliver.Relup.Instructions
      alias ReleaseManager.Config
      import Edeliver.Relup.InsertInstruction
      import Edeliver.Relup.ShiftInstruction

      @type instruction :: :relup.instruction
      @type instructions :: [instruction]

      @type insert_fun :: ((%Instructions{}|instructions, new_instructions::instruction|instructions) -> updated_instructions::%Instructions{}|instructions)

    end
  end

end