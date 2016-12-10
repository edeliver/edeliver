### Relup-Patching

edeliver provides a mechanism to automatically patch / modify the generated relup instrunctions for a release upgrade.

This is often required depending on the application to upgrade and depending on the changes made on the code.

To automatically modify the relup file the `Edeliver.Relup.Modification` behaviour must be implemented. It can call
several implementations of the `Edeliver.Relup.Instruction` behaviour in its `modify_relup/2` callback which
represent single modifications.

#### Default Relup-Patching used by edeliver

At the moment there exist two experimental default modifications, one general for all applications
(`Edeliver.Relup.DefaultModification`) and one for [phoenix](http://www.phoenixframework.org/)
applications (`Edeliver.Relup.PhoenixModification`).

To disable the automatic relup modifications you can use the `--skip-relup-mod` option when building the upgrade.

#### Instructions provided by edeliver

If you want or need to implement your own `Edeliver.Relup.Modification`, the following instructions provided by edeliver can be used:

 - `Edeliver.Relup.Instructions.CheckProcessesRunningOldCode`: aborts the upgrade if processes uses old code from previous upgrades
 - `Edeliver.Relup.Instructions.CheckRanchAcceptors`: checks whether ranch acceptors can be found or aborts the upgrade
 - `Edeliver.Relup.Instructions.CheckRanchConnections`: checks whether ranch connections can be found or aborts the upgrade
 - `Edeliver.Relup.Instructions.CodeChangeOnAppProcesses`: runs `code_change` on suspended processes
 - `Edeliver.Relup.Instructions.FinishRunningRequests`: notifies running phoenix requests that an upgrade starts
 - `Edeliver.Relup.Instructions.Info`: prints info to the log on the nodes and the edeliver upgrade output
 - `Edeliver.Relup.Instructions.ReloadModules`: reloads changed modules
 - `Edeliver.Relup.Instructions.RerunFailedRequests`: reruns phoenix requests that failed during the upgrade
 - `Edeliver.Relup.Instructions.ResumeAppProcesses`: resumes suspended processes
 - `Edeliver.Relup.Instructions.ResumeChannels`: resumes suspended phoenix channels
 - `Edeliver.Relup.Instructions.ResumeRanchAcceptors`: resumes suspended ranch acceptors
 - `Edeliver.Relup.Instructions.Sleep`: sleeps some time. useful for upgrade testing
 - `Edeliver.Relup.Instructions.SoftPurge`: replaces `:brutal_purge` with `:soft_purge` in code-loading instructions
 - `Edeliver.Relup.Instructions.StartSection`: prints info to the log on the nodes and the edeliver upgrade output that a new upgrade section starts
 - `Edeliver.Relup.Instructions.SuspendAppProcesses`: suspends processes using changed code
 - `Edeliver.Relup.Instructions.SuspendChannels`: suspends phoenix channels
 - `Edeliver.Relup.Instructions.SuspendRanchAcceptors`: suspends ranch acceptors

#### Custom Instructions

If you want to use a custom instruction in your custom `Edeliver.Relup.Modification` you must implement the `Edeliver.Relup.Instruction`
behaviour and implement the `modify_relup/2` callback. This allows e.g. to reorder, to add or to remove
[relup instructions](http://erlang.org/doc/man/appup.html).

If you just want to execute custom code during the upgrade you might want to use the more extended `Edeliver.Relup.RunnableInstruction`
behaviour and implement the `run/1` function.

If you think the custom instruction might be useful also for other applications, feel free to submit a pull request.

#### Example

This example shows a custom (runnable) instruction which would execute pending ecto migrations during the upgrade.
This custom instruction is then used in a custom relup modification which adds this instruction at the end of
the generated relup instructions including some info output (`Edeliver.Relup.Instructions.StartSection`).

```elixir

defmodule MyApp.Relup.MigrationInstruction do
  @moduledoc """
    Executes ecto migrations during the upgrade.

    Can be used in any relup modification.
  """
  use Edeliver.Relup.RunnableInstruction

  @doc "insert after all other instructions"
  def insert_where, do: &append/2

  @doc "pass application name and version to the `run/1` function when executing the relup"
  def arguments(_instructions = %Instructions{up_version: up_version}, _config = %{name: name}) do
    {name |> String.to_atom, up_version}
  end

  @doc "runs during upgrade"
  def run({otp_application_name, up_version}) do
    info "Running pending migrations..."
    {:ok, [ecto_repository_module]} = Application.fetch_env(otp_application_name, :ecto_repos) # requires ecto 2.0
    Ecto.Migrator.run(ecto_repository_module, migrations_dir(otp_application_name, up_version), :up, [all: true])
  end

  defp migrations_dir(application_name, application_version) do
    # use priv dir from the new version
    lib_dir = :code.priv_dir(application_name) |> to_string |> Path.dirname |> Path.dirname
    application_with_version = "#{Atom.to_string(application_name)}-#{application_version}"
    Path.join([lib_dir, application_with_version, "priv", "repo", "migrations"])
  end

end

defmodule MyApp.Relup.MigrationModification
  @moduledoc """
    Runs pending migrations during the upgrade

    in addition to the generated code-chaning instructions.
  """
  use Edeliver.Relup.Modification

  def modify_relup(instructions = %Instructions{}, config = %{}) do
    instructions
    # check whether upgrade is possible
    |> Edeliver.Relup.Instructions.StartSection.modify_relup(config, :check)
    |> Edeliver.Relup.Instructions.CheckProcessesRunningOldCode.modify_relup(config)
    # run the upgrade
    |> Edeliver.Relup.Instructions.SoftPurge.modify_relup(config)
    |> Edeliver.Relup.Instructions.SuspendAppProcesses.modify_relup(config)
    |> Edeliver.Relup.Instructions.ReloadModules.modify_relup(config)
    |> Edeliver.Relup.Instructions.CodeChangeOnAppProcesses.modify_relup(config)
    # run the custom instruction
    |> MyApp.Relup.MigrationInstruction.modify_relup(config) # <--------------------
    |> Edeliver.Relup.Instructions.ResumeAppProcesses.modify_relup(config)
    |> Edeliver.Relup.Instructions.StartSection.modify_relup(config, :finished)
  end

  @doc "usable if ecto is a dependency"
  def usable?(_config = %{}) do
    deps = Mix.Project.config[:deps]
    List.keymember?(deps, :ecto, 0)
  end

  @doc "returns higher priority as the edeliver defaults"
  def priority, do: priority_user
end

```
