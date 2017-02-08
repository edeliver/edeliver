eDeliver Versions
=================

__1.4.2__

- Support Elixir 1.3.4 in addition to 1.4

__1.4.1__

- Compatibility with elixir 1.4
- Compatibility with elixir versions 1.3.[0-3]
- Improved support for distillery as build tool

__1.4.0__

- Marked `:exrm` as `:optional` dependency. This __requires to add `:exrm`
  as dependency to the mix file of the project__ if exrm is used as build tool
- Allow to build releases using [distillery](https://github.com/bitwalker/distillery)
- Improve detection whether exrm or distillery is used as build tool

__1.3.0__

- Support distillery as release tool
- Add pre/post hook which is executed when deployed release is (re)started.
- Improve default automatic relup modifications and their api docs
- Fix compile warnings when compiling with elixir version >= `1.3.0`
- Fix problem with node command output

__1.2.10__

- Install also rebar3 on the build host
- Compatibility with elixir / mix version `1.3.0`
- Keep only valid SemVer characters in branch name from auto-versioning
- Fix ssh forwarding in non-verbose mode

__1.2.9__

- Fix detecting version of single release file
- Improve branch detection for auto-versioning
- Warn if `--auto-version` is used with `--skip-mix-clean`
- Avoid user interaction for `mix local.rebar` command

__1.2.8__

- Add `update` command to build and deploy in a single step
- Allow to append mix env as metadata to version
- Exrm `1.0.5` compatibility for node commands
- Allow to link sys.config and vm.args for each mix env

__1.2.7__

- Allow to use umbrella projects also for the `upgrade` or `build upgrade` task
- Use ssh agent forwarding on build host to allow to use private git repositories as dependencies

__1.2.6__

- Restart whole vm with most recent release for the `restart` command or `--start-deploy` option
- (Re-)start node(s) synchronously and print start progress for `--verbose` option
- Fix `upgrade` command for production deploy environments
- Improved error output

__1.2.5__

- Fix error on automatic phoenix upgrades by not suspending the ranch acceptors supervisor
- Fix passing `ECTO_REPOSITORY` env to ecto migration tasks
- Ecto 2.0 support: read ecto_repos from application env
- Fix skipping automatic relup modifications for upgrades
- Fix changing the version of an old release which is build for an upgrade
- Fix `--mix-env` option

__1.2.4__

- Support migrations for ecto version >= 2.0

__1.2.3__

- Improve displaying of revisions contained in the running release.

__1.2.2__

- Fix detecting branch name on build host for `--autoversion=branch[-unless-master]` option.

__1.2.1__

- Fix syntax on migrate task with down operation

__1.2.0__

- Add `upgrade` task to automatically upgrade all nodes
- Add auto-versioning to append metadata to release versions
- Add command help `mix edeliver help <command>`
- Add automatic relup modifications
- Experimental support for auto-upgrades of phoenix apps

__1.1.6__

- Fix issue caused by CDPATH being set

__1.1.5__

- Fix displaying all output for node commands

__1.1.4__

- Fix selecting release when deploying and no version is given

__1.1.3__

- Fix hex.pm release by adding missing mix.exs

__1.1.2__

- Fix ssh warning if edeliver is used as mix task
- Allow user interaction when building in verbose mode
- Suppress printing app script version if app script was generated with recent exrm version
- Fix skipping git clean when SKIP_GIT_CLEAN env is set
- Show very verbose output of exrm release task if it fails
- Fix name of post hook which is executed after updating the deps

__1.1.1__

- added command line option `--mix-env=<env>`
- automatic authorization of/on release store host
- allow to build different apps in one project when `APP` env is used
- use always explicit compilation for exrm compatibility

__1.1.0__

- allow incremental builds to decrease build time
- support for executing ecto migrations
- support exrm versions from `0.16.0` to > `1.0.0`
- allow to link sys.config and vm.args in release
- display command output when build command failed
- keeps build repository size constant
- return correct status code if mix command failed
- deploy release non-interactively if also upgrade exists
- install hex non-interactive


__1.0.0__

 - initial version with elixir support
