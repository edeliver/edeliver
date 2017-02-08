defmodule Edeliver.Relup.Modification do
  @moduledoc """
    This behaviour can be used to provide custom modifications of
    relup instructions

    when a release upgrade is built by edeliver.

    By default the implementation from `Edeliver.Relup.PhoenixModification` is used
    for phoenix applications and for all others the implementation from
    `Edeliver.Relup.DefaultModification`.

    Implementations can modify the relup instructions step by step by using
    modules implementing the `Edeliver.Relup.Instruction` behaviour.

    The implementation returning the highest `priority/0` or which is passed by the
    `--relup-mod=` command line option will be used unless the `--skip-relup-mod`
    option is set.

    Example:

      defmodule Acme.Relup.Modification do
        use Edeliver.Relup.Modification

        def modify_relup(instructions = %Instructions{}, config = %{}) do
          instructions |> Edeliver.Relup.DefaultModification.modify_relup(config) # use default modifications
                       |> log_upgrade # add custom modifcation which logs the upgrade
        end

        defp log_upgrade(instructions = %Instructions{up_instructions: up_instructions}) do
          log_instruction = {apply, {:Elixir.Logger, info, [<<"Upgraded successfully">>]}}
          %{instructions| up_instructions: [log_instruction|up_instructions]}
        end
      end

  """

  @doc """
    Modifies the relup instructions and returns the modified instruction
  """
  @callback modify_relup(Edeliver.Relup.Instructions.t, Edeliver.Relup.Config.t) :: Edeliver.Relup.Instructions.t

  @doc """
    Default priority for builtin relup modifications
  """
  @spec priority_default :: 1
  def priority_default, do: 1

  @doc """
    Default priorty for user defined relup modificaitons
  """
  @spec priority_user :: 1000
  def priority_user, do: 1_000

  @doc """
    Priority lower as the default priority which can be used temporarily to
    disable user defined relup modifications and use the defaults
  """
  @spec priority_none :: 0
  def priority_none, do: 0


  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Edeliver.Relup.Modification
      alias Edeliver.Relup.Instructions
      import Edeliver.Relup.Modification, only: [priority_default: 0, priority_user: 0, priority_none: 0]

      Module.register_attribute __MODULE__, :name, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :moduledoc, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :shortdoc, accumulate: false, persist: true

      @doc """
        Returns the priority of this modification. Unless the module is set by the
        `RELUP_MODIFICATION_MODULE` env or the `--relup-mod=` command line option
        the module with the highest priority is used (which is also usable).
      """
      @spec priority() :: non_neg_integer
      def priority, do: priority_user()

      @doc """
        Returns true if this relup modification is usable for the project or not.

        E.g. the `Edeliver.Relup.PhoenixModifcation` returns true only if the
        project is a phoenix project. This function returns `true` by default
        can be overridden in a custom `Edeliver.Relup.Modification` behaviour
        implementation.
      """
      @spec usable?(Edeliver.Relup.Config.t) :: boolean
      def usable?(_config = %{}), do: true

      defoverridable [priority: 0, usable?: 1]

    end
  end


end