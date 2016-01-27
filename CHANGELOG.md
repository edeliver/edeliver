eDeliver Versions
=================

1.1.2

- Fix ssh warning if edeliver is used as mix task
- Allow user interaction when building in verbose mode
- Suppress printing app script version if app script was generated with recent exrm version
- Fix skipping git clean when SKIP_GIT_CLEAN env is set
- Show very verbose output of exrm release task if it fails
- Fix name of post hook which is executed after updating the deps

1.1.1

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