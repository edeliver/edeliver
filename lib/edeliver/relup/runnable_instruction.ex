defmodule Edeliver.Relup.RunnableInstruction do
  @moduledoc """
    This module can be used to provide custom instructions executed during the upgrade.

    They can be used in implementations of the `Edeliver.Relup.Modification` behaviours.
    A runnable instruction  must implement a `c:Edeliver.Relup.RunnableInstruction.run/1` function which will be executed
    during the upgrade on the nodes.

    Example:

      defmodule Acme.Relup.PingNodeInstruction do
        use Edeliver.Relup.RunnableInstruction

        def modify_relup(instructions = %Instructions{up_instructions: up_instructions}, _config = %{}) do
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

        def modify_relup(instructions = %Instructions{}, config = %{}) do
          instructions |> Edeliver.Relup.DefaultModification.modify_relup(config) # use default modifications
                       |> Acme.Relup.PingNodeInstruction.modify_relup(config) # apply also custom instructions
        end
      end

  """
  require Logger
  import Edeliver.Relup.ShiftInstruction, only: [
    ensure_module_loaded_before_first_runnable_instructions: 3,
    ensure_module_unloaded_after_last_runnable_instruction: 3,
  ]
  alias Edeliver.Relup.Instructions


  @doc """
    The function to run during hot code upgrade on nodes.

    If it throws an error before the `point_of_no_return` the
    upgrade is aborted. If it throws an error and was executed
    after that point, the release is restarted
  """
  @callback run(options::[term]) :: :ok

  @doc """
    Returns a function which inserts the relup instruction

    that calls the `c:Edeliver.Relup.RunnableInstruction.run/1` fuction of this module.
    Default is inserting it at the end of the instructions
  """
  @callback insert_where() :: ((%Edeliver.Relup.Instructions{}, Edeliver.Relup.Instruction.instruction) -> %Edeliver.Relup.Instructions{})

  @doc """
    Returns the arguments which will be passed the `c:Edeliver.Relup.RunnableInstruction.run/1` function during the upgrade.

    Default is an empty list.
  """
  @callback arguments(instructions::%Edeliver.Relup.Instructions{}, config::Edeliver.Relup.Config.t) :: [term]

  @doc """
    Returns a list of module names which implement the behaviour `Edeliver.Relup.RunnableInstruction`

    and are used / referenced by this runnable instruction. These modules must be loaded before this instruction
    is executed for upgrades and unloaded after this instruction for downgrades. Default is an empty list.
  """
  @callback dependencies() :: [instruction_module::atom]

  @doc """
    Logs the message of the given type on the node

    which executes the upgrade and displays it as output of
    the `$APP/bin/$APP upgrade $RELEASE` command. The message is
    prefixed with a string derived from the message type.
  """
  @spec log_in_upgrade_script(type:: :error|:warning|:info|:debug, message::String.t) :: no_return
  def log_in_upgrade_script(type, message) do
    message = String.to_char_list(message)
    prefix = case type do
      :error   -> '---> X '
      :warning -> '---> ! '
      :info    -> '---> '
      _        -> '----> ' # debug
    end
    format_in_upgrade_script('~s~s~n', [prefix, message])
  end

  @doc """
    Formats and prints the message on the node

    running the upgrade script which was started by the
    `$APP/bin/$APP upgrade $RELEASE` command.
  """
  @spec format_in_upgrade_script(format::char_list, arguments::[term]) :: no_return
  def format_in_upgrade_script(format, arguments) do
    :erlang.nodes |> Enum.filter(fn node ->
      Regex.match?(~r/upgrader_\d+/, Atom.to_string(node))
    end) |> Enum.each(fn node ->
      :rpc.cast(node, :io, :format, [:user, format, arguments])
    end)
  end

  @doc """
    Logs an error using the `Logger` on the running node which is upgraded.

    In addition the same error message is logged on the node which executes
    the upgrade and is displayed as output of the
    `$APP/bin/$APP upgarde $RELEASE` command.
  """
  @spec error(message::String.t) :: no_return
  def error(message) do
    Logger.error message
    log_in_upgrade_script(:error, message)
  end

  @doc """
    Logs a warning using the `Logger` on the running node which is upgraded.

    In addition the same warning message is logged on the node which executes
    the upgrade and is displayed as output of the
    `$APP/bin/$APP upgarde $RELEASE` command.
  """
  @spec warn(message::String.t) :: no_return
  def warn(message) do
    Logger.warn message
    log_in_upgrade_script(:warning, message)
  end

  @doc """
    Logs an info message using the `Logger` on the running node which is upgraded.

    In addition the same info message is logged on the node which executes
    the upgrade and is displayed as output of the
    `$APP/bin/$APP upgarde $RELEASE` command.
  """
  @spec info(message::String.t) :: no_return
  def info(message) do
    Logger.info message
    log_in_upgrade_script(:info, message)
  end

  @doc """
    Logs a debug message using the `Logger` on the running node which is upgraded.

    In addition the same debug message is logged on the node which executes
    the upgrade and is displayed as output of the
    `$APP/bin/$APP upgarde $RELEASE` command.
  """
  @spec debug(message::String.t) :: no_return
  def debug(message) do
    Logger.debug message
    log_in_upgrade_script(:debug, message)
  end

  @doc """
    Ensures that all `Edeliver.Relup.RunnableInstruction` modules used / referenced by this instruction
    and returned by the `c:Edeliver.Relup.RunnableInstruction.dependencies/0` callback are loaded before this instruction is executed
    during the upgrade.
  """
  @spec ensure_dependencies_loaded_before_instruction_for_upgrade(instructions::Instructions.t, runnable_instruction::{:apply, {module::atom, :run, arguments::[term]}}, dependencies::[instruction_module::atom]) :: Instructions.t
  def ensure_dependencies_loaded_before_instruction_for_upgrade(instructions = %Instructions{}, call_this_instruction, dependencies) do
    dependencies |> Enum.reduce(instructions, fn(dependency, instructions_acc = %Instructions{up_instructions: up_instructions}) ->
      %{instructions_acc| up_instructions: ensure_module_loaded_before_first_runnable_instructions(up_instructions, call_this_instruction, dependency)}
    end)
  end

  @doc """
    Ensures that all `Edeliver.Relup.RunnableInstruction` modules used / referenced by this instruction
    and returned by the `c:Edeliver.Relup.RunnableInstruction.dependencies/0` callback are unloaded after this instruction is executed
    during the downgrade.
  """
  @spec ensure_dependencies_unloaded_after_instruction_for_downgrade(instructions::Instructions.t, runnable_instruction::{:apply, {module::atom, :run, arguments::[term]}}, dependencies::[instruction_module::atom]) :: Instructions.t
  def ensure_dependencies_unloaded_after_instruction_for_downgrade(instructions = %Instructions{}, call_this_instruction, dependencies) do
    dependencies |> Enum.reduce(instructions, fn(dependency, instructions_acc = %Instructions{down_instructions: down_instructions}) ->
      %{instructions_acc| down_instructions: ensure_module_unloaded_after_last_runnable_instruction(down_instructions, call_this_instruction, dependency)}
    end)
  end

  @doc """
    Assumes that the pattern matches or throws an error with the given error message.

    The error message is logged as error to the logfile
    using the `Logger` and displayed as error output by the
    `$APP/bin/$APP upgrade $RELEASE` task using the
    `$APP/ebin/install_upgrade.escript` script. If the pattern matches
    the variables from the matching are assigned.
  """
  defmacro assume({:=, _, [left, right]} = assertion, error_message) do
    code = Macro.escape(assertion)

    left = Macro.expand(left, __CALLER__)
    vars = collect_vars_from_pattern(left)

    quote do
      right = unquote(right)
      expr  = unquote(code)
      unquote(vars) =
        case right do
          unquote(left) ->
            unquote(vars)
          _ ->
            error unquote(error_message)
            # error is shown as erlang term in the upgrade script
            # `$APP/ebin/install_upgrade.escript`. so use an erlang
            # string as error message
            throw {:error, String.to_char_list(unquote(error_message))}
        end
      right
    end
  end

  # Used by the assume macro for pattern assignment
  defp collect_vars_from_pattern(expr) do
    {_, vars} =
      Macro.prewalk(expr, [], fn
        {:::, _, [left, _]}, acc ->
          {[left], acc}
        {skip, _, [_]}, acc when skip in [:^, :@] ->
          {:ok, acc}
        {:_, _, context}, acc when is_atom(context) ->
          {:ok, acc}
        {name, _, context}, acc when is_atom(name) and is_atom(context) ->
          {:ok, [{name, [generated: true], context}|acc]}
        node, acc ->
          {node, acc}
      end)
    Enum.uniq(vars)
  end

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Edeliver.Relup.Instruction
      import Edeliver.Relup.RunnableInstruction
      @behaviour Edeliver.Relup.RunnableInstruction
      alias Edeliver.Relup.Instructions
      require Logger

      def modify_relup(instructions = %Instructions{}, config = %{}) do
        call_this_instruction = call_this(arguments(instructions, config))
        insert_where_fun = insert_where()
        instructions |> insert_where_fun.(call_this_instruction)
                     |> ensure_module_loaded_before_instruction(call_this_instruction, __MODULE__)
                     |> ensure_dependencies_loaded_before_instruction_for_upgrade(call_this_instruction, dependencies())
                     |> ensure_dependencies_unloaded_after_instruction_for_downgrade(call_this_instruction, dependencies())
      end

      @spec arguments(%Edeliver.Relup.Instructions{}, Edeliver.Relup.Config.t) :: term
      def arguments(%Edeliver.Relup.Instructions{}, %{}), do: []

      @spec insert_where()::Instruction.insert_fun
      def insert_where, do: &append/2

      @spec dependencies() :: [instruction_module::atom]
      def dependencies, do: []


      defoverridable [modify_relup: 2, insert_where: 0, arguments: 2, dependencies: 0]

      @doc """
        Calls the `run/1` function of this module

        from the  relup file during hot code upgrade
      """
      @spec call_this(arguments::[term]) :: Instruction.instruction|Instruction.instructions
      def call_this(arguments \\ []) do
        {:apply, {__MODULE__, :run, [arguments]}}
      end

    end # quote

  end # defmacro __using__


end