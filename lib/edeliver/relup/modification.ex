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

  @doc """
    Modifies the relup instructions and returns the modified instruction
  """
  @callback modify_relup(Edeliver.Relup.Instructions.t, ReleaseManager.Config.t) :: Edeliver.Relup.Instructions.t

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Edeliver.Relup.Modification
      alias Edeliver.Relup.Instructions
      alias ReleaseManager.Config

      Module.register_attribute __MODULE__, :name, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :moduledoc, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :shortdoc, accumulate: false, persist: true

      @doc """
        Returns the priority of this modification. Unless the module is set by the
        `RELUP_MODIFICATION_MODULE` env or the `--relup-mod=` command line option
        the module with the highest priority is used (which is also usable).
      """
      @spec priority() :: non_neg_integer
      def priority, do: priority_user

      @doc """
        Returns true if this relup modification is usable for the project or not.
        E.g. the `Edeliver.Relup.PhoenixModifcation` returns true only if the
        project is a phoenix project
      """
      @spec usable?(ReleaseManager.Config.t) :: boolean
      def usable?(_config = %Config{}), do: true

      defoverridable [priority: 0, usable?: 1]

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
    end
  end


end