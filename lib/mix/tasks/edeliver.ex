defmodule Mix.Tasks.Edeliver do
  use Mix.Task

  @shortdoc "Build and deploy releases"

  @moduledoc """
  Build and deploy Elixir applications and perform hot-code upgrades

  ## Usage:

    * mix edeliver <build-command|deploy-command|node-command|local-command> command-info [Options]
    * mix edeliver --help|--version

  # Build Commands:

    * mix edeliver build release [--revision=<git-revision>|--tag=<git-tag>] [--branch=<git-branch>] [Options]
    * mix edeliver build appups|upgrade --from=<git-tag-or-revision>|--with=<release-version-from-store> [--to=<git-tag-or-revision>] [--branch=<git-branch>] [Options]

  ## Deploy Commands:

    * mix edeliver deploy release|upgrade [[to] staging|production] [--version=<release-version>] [Options]

  ## Node Commands:

    * mix edeliver start|stop|restart|ping|version [staging|production] [Options]
    * mix edeliver migrate [staging|production] [up|down] [--version=<migration-version>]
    * mix edeliver [show] migrations [on] [staging|production]

  ## Local Commands:

    * mix edeliver check release|config [--version=<release-version>]
    * mix edeliver show releases|appups
    * mix edeliver show relup <xyz.upgrade.tar.gz>
    * mix edeliver edit relup|appups [--version=<release-version>]
    * mix edeliver upload|download [release|upgrade <release-version>]|<src-file-name> [<dest-file-name>]
    * mix edeliver increase [major|minor] versions [--from=<git-tag-or-revision>] [--to=<git-tag-or-revision>]
    * mix edeliver unpack|pack release|upgrade [--version=<release-version>]

  ## Command line options
    * `--quiet` - do not output verbose messages
    * `--only`  - only fetch dependencies for given environment
    * `-C`, `--compact` Displays every task as it's run, silences all output. (default mode)
    * `-V`, `--verbose` Same as above, does not silence output.
    * `-P`, `--plain` Displays every task as it's run, silences all output. No colouring. (CI)
    * `-D`, `--debug` Runs in shell debug mode, displays everything.
    * `-S`, `--skip-existing` Skip copying release archives if they exist already on the deploy hosts.
    * `-F`, `--force` Do not ask, just do, overwrite, delete or destroy everything
    * `--clean-deploy` Delete the release, lib and erts-* directories before deploying the release
    * `--start-deploy` Starts the deployed release. If release is running, it is restarted!
    * `--host=[u@]vwx.yz` Run command only on that host, even if different hosts are configured
    * `--skip-git-clean` Don't build from a clean state for faster builds. By default all built files are removed before the next build using `git clean`. This can be adjusted by the $GIT_CLEAN_PATHS env.
    * `--skip-mix-clean` Skip the 'mix clean step' for faster builds. Makes only sense in addition to the --skip-git-clean

  """
  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    edeliver = Path.join [Mix.Project.config[:deps_path], "edeliver", "bin", "edeliver"]
    if (res = Mix.shell.cmd(Enum.join([edeliver | args], " "))) > 0, do: System.halt(res)
  end
end