<img src="http://boldpoker.net/images/edeliver_500.png" width=120>

# edeliver

_Deployment for Elixir and Erlang_

[![Hex.pm](http://img.shields.io/hexpm/v/edeliver.svg)](https://hex.pm/packages/edeliver) [![Hex.pm](http://img.shields.io/hexpm/dt/edeliver.svg)](https://hex.pm/packages/edeliver)


**edeliver** is based on [deliver](https://github.com/gerhard/deliver) and enables you to build and deploy Elixir and Erlang applications and perform hot-code upgrades.

The [erlang releases](http://www.erlang.org/doc/design_principles/release_handling.html) are built on a *remote* host that is similar to the production machines.  After being built, the release can then be deployed to one or more production machines.

Once built, the [release](http://www.erlang.org/doc/design_principles/release_handling.html) contains the full [erts (erlang runtime system)](http://erlang.org/doc/apps/erts/users_guide.html), all [dependencies (erlang or elixir applications)](http://www.erlang.org/doc/design_principles/applications.html), the Elixir runtime, native port drivers, and your erlang/elixir application(s) in a standalone embedded node.


## Community

- [Issues](https://github.com/boldpoker/edeliver/issues)
- [#deployment on Slack](https://elixir-lang.slack.com/)
- [Community Wiki](https://github.com/boldpoker/edeliver/wiki) — _feel free to contribute!_


## Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Build Commands](#build-commands)
- [Deploy Commands](#deploy-commands)
- [Admin Commands](#admin-commands)
- [Help](#help)
- [Examples](#examples)
- [License](#license)


## Quick Start

Assuming an Elixir project, you already have a build server and a staging server, and you've created a database on your staging server already (there is no ecto.create, we skip straight to migrations).

Add edeliver and your build tool ([distillery](https://github.com/bitwalker/distillery) or [exrm](https://github.com/bitwalker/exrm)) to your project dependencies in mix.exs:

```exs
def application, do: [
  applications: [
  	 ...
    # Add edeliver to the END of the list
    :edeliver
  ]
]

defp deps do
  [
    ...
    {:edeliver, "~> 1.4.2"},
    {:distillery, ">= 0.8.0", warn_missing: false},
    # or :exrm
  ]
end
```

If this is a Phoenix project, upload your prod.secret.exs to your build server somewhere.  Let's say it's at /home/builder/prod.secret.exs.

In your project, create the file .deliver/config

```bash
# .deliver/config

APP="myapp"

BUILD_HOST="my-build-server.myapp.com"
BUILD_USER="builder"
BUILD_AT="/tmp/edeliver/myapp/builds"

STAGING_HOSTS="stage.myapp.com"
STAGING_USER="web"
DELIVER_TO="/home/web"

# For *Phoenix* projects, symlink prod.secret.exs to our tmp source
pre_erlang_get_and_update_deps() {
  local _prod_secret_path="/home/builder/prod.secret.exs"
  if [ "$TARGET_MIX_ENV" = "prod" ]; then
    __sync_remote "
      ln -sfn '$_prod_secret_path' '$BUILD_AT/config/prod.secret.exs'
    "
  fi
}
```

Add the release directory to your gitignore

```console
echo ".deliver/releases/" >> .gitignore
```

Commit everything, compile the new dependencies:

```console
git add -A && git commit -m "Setting up edeliver"
mix do deps.get, compile
```

Now you can release with edeliver!

```console
mix edeliver update
mix edeliver start
mix edeliver migrate
```


## Installation

Because it is based on [deliver](https://github.com/gerhard/deliver), it uses only shell scripts and has no further dependencies except the Erlang/Elixir build system.

It can be used with any one of these build systems:

  * [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) in conjunction with [distillery](https://github.com/bitwalker/distillery) for elixir/erlang releases (recommended)
  * [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) in conjunction with [exrm](https://github.com/bitwalker/exrm) for elixir/erlang releases
  * [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) in conjunction with [relx](https://github.com/erlware/relx) for elixir/erlang releases
  * [rebar](https://github.com/basho/rebar) for pure erlang releases

Edeliver tries to autodetect which system to use:

  * If a `./mix.exs` and a `rel/config.exs` file exists, [mix](http://elixir-lang.org/getting_started/mix/1.html) is used fetch the dependencies, compile the sources and [distillery](https://github.com/bitwalker/distillery) is used to generate the releases / upgrades.
  * If a `./mix.exs` file exists, [mix](http://elixir-lang.org/getting_started/mix/1.html) is used fetch the dependencies, compile the sources and [exrm](https://github.com/bitwalker/exrm) is used to generate the releases / upgrades.
  * If a `./relx.config` file exists in addition to a `./mix.exs` file, [mix](http://elixir-lang.org/getting_started/mix/1.html) is used fetch the dependencies, compile the sources and [relx](https://github.com/erlware/relx) is used to generate the releases / upgrades.
  * Otherwise [rebar](https://github.com/basho/rebar) is used to fetch the dependencies, compile the sources and generate the releases / upgrades.

This can be overridden by the config variables `BUILD_CMD=rebar|mix`, `RELEASE_CMD=rebar|mix|relx` and `USING_DISTILLERY=true|false` in `.deliver/config`.

Edeliver uses ssh and scp to build and deploy the releases.  It is recommended that you use ssh and scp with key+passphrase only.  You can use `ssh-add` if you don't want to enter your passphrase every time.

It may be required to install and configure git on your build host. You may also have to clone the repository initially at the `BUILD_AT` path, although edeliver will try to take care of this for you. [Erlang](http://www.erlang.org/) and [Elixir](http://elixir-lang.org/) must be installed and available on the `BUILD_HOST`. The default shell for the build and deploy user should be `bash` or `zsh` on your build and deployment systems (check that especially if you are [running FreeBSD](https://www.freebsd.org/doc/en/articles/linux-users/shells.html)).

The build host must be similar to the production/staging hosts.  For example, if you want to deploy to a production system based on Linux, the release must also be built on a Linux system.

The Erlang runtime (OTP) and the Elixir runtime are packaged with the release—you do not have to install Erlang or Elixir separately on your production/staging servers.


### Mix considerations

If using [mix](http://elixir-lang.org/getting_started/mix/1.html), add edeliver and your build tool and your build tool ([distillery](https://hex.pm/packages/distillery) or [exrm](https://hex.pm/packages/exrm)) as [hex package](https://hex.pm/packages/edeliver) to your `mix.exs` config:

```exs
defp deps do
  [
  	{:edeliver, ">= 1.4.2"},
    {:distillery, ">= 0.8.0", warn_missing: false},
	# or {:exrm, ">= 0.16.0", warn_missing: false},
  ]
end
```

Run `mix do deps.get, deps.compile`.  Edeliver is then available as a mix task: `mix edeliver`.

Some edeliver commands used for server administration require that edeliver be running on the server itself so that it can respond.  These commands include `version`, `migrate`, `show migrations`, etc.  To enable this, add edeliver as application to be started in `mix.exs`.  It should be added last at the _end_ of the list:

```exs
def application, do: [
  applications: [
    # ...
    :edeliver,
  ],
]
```

### Rebar considerations

When using rebar, edeliver can be added as [rebar](https://github.com/basho/rebar) dependency. Just add it to your `rebar.config` (and ensure that a `./rebar` binary/link is in your project directory):

    {deps, [
      % ...
      {edeliver, "1.4.2",
        {git, "git://github.com/boldpoker/edeliver.git", {branch, master}}}
    ]}.

And link the `edeliver` binary to the root of your project directory:

    ./rebar get-deps # when using rebar, or ...
    ln -s ./deps/edeliver/bin/edeliver .

Then use the linked binary `./edeliver` instead of the `mix edeliver` tasks from the examples.


## Configuration

Create a `.deliver` directory in your project folder and add the `config` file:

```sh
#!/usr/bin/env bash

APP="your-erlang-app" # name of your release

BUILD_HOST="build-system.acme.org" # host where to build the release
BUILD_USER="build" # local user at build host
BUILD_AT="/tmp/erlang/my-app/builds" # build directory on build host

STAGING_HOSTS="test1.acme.org test2.acme.org" # staging / test hosts separated by space
STAGING_USER="test" # local user at staging hosts
TEST_AT="/test/my-erlang-app" # deploy directory on staging hosts. default is DELIVER_TO

PRODUCTION_HOSTS="deploy1.acme.org deploy2.acme.org" # deploy / production hosts separated by space
PRODUCTION_USER="production" # local user at deploy hosts
DELIVER_TO="/opt/my-erlang-app" # deploy directory on production hosts
```

To use different configurations on different hosts, you can [configure edeliver to link](https://github.com/boldpoker/edeliver/wiki/Use-per-host-configuration) the `vm.args` and/or the `sys.config` files in the release package by setting the `LINK_VM_ARGS=/path/to/vm.args` and/or `LINK_SYS_CONFIG=/path/to/sys.config` variables in the edeliver config if you use [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) and [exrm](https://github.com/bitwalker/exrm) or [distillery](https://github.com/bitwalker/distillery) to build the releases.

Another strategy is to use runtime environment variable evaluation (available for [exrm](https://github.com/bitwalker/exrm) and [relx](https://github.com/erlware/relx)). For more information on this technique, see [Plataformatec - Deploying Elixir with edeliver](http://blog.plataformatec.com.br/2016/06/deploying-elixir-applications-with-edeliver/)

If you wish to use `RELX_REPLACE_OS_VARS=true`, ensure this is _exported_ in your deployment environment and all the environment variables which should replace default configuration.

For example in `~/.profile`

```sh
export RELX_REPLACE_OS_VARS=true
export MY_CUSTOM_DATABASE_PORT=5433
```

## Build Commands

For build commands the following **configuration** variables must be set:

- `APP`: the name of your release which should be built
- `BUILD_HOST`: the host where to build the release
- `BUILD_USER`: the local user at build host
- `BUILD_AT`: the directory on build host where to build the release. must exist.

The built release is then **copied to your local directory** `.deliver/releases` and can then be **delivered to your production servers** by using one of the **deploy commands**.

If compiling and generating the release build was successful, the release is **copied from the remote build host** to the **release store**. The default release store is the __local__ `.deliver` __directory__ but you can configure any destination with the `RELEASE_STORE=` environment variables, also __remote ssh destinations__ (in your server network) like `RELEASE_STORE=user@releases.acme.org:/releases/` or **amazon s3** locations like `s3://AWS_ACCESS_KEY_ID@AWS_SECRET_ACCESS_KEY:bucket`. The release is copied from the remote build host using the `RELEASE_DIR=` environment variable. If this is not set, the default directory is found by finding the subdirectory that contains the generated `RELEASES` file and has the `$APP` name in the path. e.g. if `$APP=myApp` and the `RELEASES` file is found at `rel/myApp/myApp/releases/RELEASE` the `rel/myApp/myApp` is copied to the release store.

To __build releases__ and upgrades __faster__, you might adjust the `GIT_CLEAN_PATHS` variable in your config file e.g. to something like `="_build rel priv/generated"` which defaults to `.`. That value means, that everything from the last build is reset (beam files, release files, deps, generated assets etc.) before the next build is started to ensure that no conflicts with old (e.g. removed or renamed) files might arise. You can also use the command line option `--skip-git-clean` to skip this step completely and in addition with the `--skip-mix-clean` option for full __incremental builds__.


### Build Initial Release

    mix edeliver build release [--revision=<git-revision>|--tag=<git-tag>] [--branch=<git-branch>]

Builds an initial release that can be deployed to the production hosts. If you want to build a different tag or revision, use the `--revision=` or the `--tag` argument. If you want to build a different branch or the tag / revision is in a different branch, use the `--branch=` argument.


### Build an upgrade package

    mix edeliver build upgrade --from=<git-tag-or-revision>|--with=<release-version-from-store>
                              [--to=<git-tag-or-revision>] [--branch=<git-branch>]

Builds an _upgrade_ package that can be deployed to production hosts with running nodes _without restarting_ them. To build an upgrade package you need the release or upgrade package (when using [exrm](https://github.com/bitwalker/exrm) or [distillery](https://github.com/bitwalker/distillery)) of the running release. If it is available (in the release store), you can build the upgrade to the new version by passing the old  version to the `--with=<old-version>` option. If not, you can build the old release and the live upgrade from it in a single step by using the `--from=<git-tag-or-revision>` option. If you don't want to build an upgrade to the current head of the given branch (`master` is the default), you can use the `--to=<git-tag-or-revision>` option. If the upgrade package is built, you might want to _modify_ the generated upgrade instructions ([relup](http://www.erlang.org/doc/man/relup.html)) as described in the next section or (more advanced) automatically patch the relup file by implementing your own [`Edeliver.Relup.Modification`](https://github.com/boldpoker/edeliver/blob/master/lib/edeliver/relup/modification.ex)behaviour to automate this step.


### Edit upgrade instructions (relup)

    mix edeliver edit relup [--version=<upgrade-version>]

From the auto-generated appup instructions of all included and updated applications, a [relup](http://www.erlang.org/doc/man/relup.html) file is generated during the `build upgrade` command and included in the upgrade package.  It contains the upgrade instructions for the new release version.  If there are dependencies between modules or applications, it might be necessary to modify this file, e.g. changing the order of the applications or modules that are reloaded.  If there are repeating steps to adjust the relup for your application, you can automate this step by implementing your own [`Edeliver.Relup.Modification`](https://github.com/boldpoker/edeliver/blob/master/lib/edeliver/relup/modification.ex) behavior.


### Auto-Versioning

edeliver provides a way to automatically increment the current version for the current build and/or to append [metadata](http://semver.org/#spec-item-10) to the version (such as the current git sha).  Having unique versions for each release is important especially if you build hot code upgrades.  It also helps to determine exactly which version is running when using `mix edeliver version`.  For more information check the `--auto-version=` option described e.g in `mix edeliver help upgrade` or in the [wiki](https://github.com/boldpoker/edeliver/wiki/Auto-Versioning).


### Build Restrictions (rebar)

To build upgrades, there must be only one release in the release directory (`rel`) of your project as configured in your `rebar.config`. E.g. if you want to build two different releases `project-dir/rel/release_a` and `project-dir/rel/release_b` you need two `rebar.config` files that refer only to either one of that release directories in the `sub_dirs` section.
You can then pass the config file to use by setting the environment `REBAR_CONFIG=` at the command line.
The reason for that is, that when the upgrade is build with rebar, rebar tries to find the old version in both release directories.


## Deploy Commands

    mix edeliver deploy release|upgrade [[to] staging|production] [--version=<release-version>] [Options]

Deploy commands deliver the builds that were created with a build command to your staging or production hosts.  They can also perform a live code upgrade.  Built releasees or upgrades are available in your local directory `.deliver/releases`.  To deploy releases the following configuration variables must be set:

- `APP`: the name of your release which should be built
- `PRODUCTION_HOSTS`: the production hosts to deploy to, separated by space
- `PRODUCTION_USER`: the local users at the production hosts
- `DELIVER_TO`: the directory at the production hosts to deploy the release at

- `STAGING_HOSTS`: the staging hosts to test the releases at, separated by space
- `STAGING_USER`: the local users at the staging hosts
- `TEST_AT`: the directory at the staging hosts. if not set, the DELIVER_TO is used as directory

Deploying to staging can be used to test your releases and upgrades before deploying them to the production hosts.  Staging is the default target if you don't pass the `[to] production` argument.


### Deploy an initial/clean release

```console
mix edeliver deploy
```

Deploys an initial release at the production hosts.  This requires that the `build release` command was executed before.

If there are several releases in the release store, you will be asked which release to deploy or you can pass the version by the `--version=` argument variable.  If the nodes on the remote deploy hosts are up, the running old release is not affected—the new release will be available only after starting or restarting the nodes on the deploy hosts.


### Deploy an upgrade

```console
mix edeliver upgrade
```

Deploys an upgrade at the production hosts and upgrades the running nodes to the new version.  This requires that the `build upgrade` command was executed before, and that there is already an initial release deployed to the production hosts, and that the node is running.

Release archives in your release store that were created by the `build release` command **cannot be used to deploy an upgrade**.

This comand requires that your release start script was **generate** by a **recent rebar version** that supports the `upgrade` command in addition to the `start|stop|ping|attach` commands. Releases generated with [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) and [exrm](https://github.com/bitwalker/exrm) or [distillery](https://github.com/bitwalker/distillery) always contain the `upgrade` command.

If using rebar, make sure that the [install_upgrade.escript](https://github.com/basho/rebar/blob/master/priv/templates/simplenode.install_upgrade.escript) file which was generated by rebar is included in your release. So ensure, that the following line is in your `reltool.config`:

    {overlay, [ ...
           {copy, "files/install_upgrade.escript", "bin/install_upgrade.escript"}
    ]}.


## Admin Commands

edeliver has a set of commands to check up on your running nodes:

```console
mix edeliver ping production # shows which nodes are up and running
mix edeliver version production # shows the release version running on the nodes
mix edeliver show migrations on production # shows pending database migrations
mix edeliver migrate production # run database migrations
mix edeliver restart production # or start or stop
```


## Help

If something goes wrong, retry with the `--verbose` option.  If you want to see everything, try the `--debug` option.

For detailed information about the edeliver commands and their options, try `mix edeliver help <command>`.

For advanced usage have a look also at the [wiki](https://github.com/boldpoker/edeliver/wiki).

Definitely join the #deployment channel in the [Elixir Slack community](https://elixir-lang.slack.com/) as well.


### Recommended Project Structure


    your-app/                              <- project root dir
      + rebar                              <- rebar binary
      + mix                                <- optional mix binary when compiling with mix
      + relx                               <- optional relx binary if rebar is not used
      + edeliver                           <- edeliver binary linking to deps/deliver/bin/deliver
      + rebar.config                       <- should have "rel/your-app" in the sub_dirs section
      + mix.exs                            <- if present, mix is used for dependencies and compile
      + relx.config                        <- if present, relx is used for releases
      + .deliver                           <- default release store
      |  + releases/*.tar.gz               <- the built releases / upgrade packages
      |  + appup/OldVsn-NewVsn/*.apppup    <- generated appup files
      |  + config                          <- deliver configuration
      + src/                               <- erlang source files
      |  + *.erl
      |  + your-app.app.src
      + lib/                               <- elixir source files
      |  + *.ex
      + priv/
      + deps/
      |  + edeliver/
      + rel/
         + your-app/
             + files/
             |   + your-app                <- binary to start|stop|upgrade your app
             |   + nodetool                <- helper for your-app binary
             |   + install-upgrade.escript <- helper for the upgrade task of your-app binary
             |   + sys.config              <- app configuration for the release build
             |   + vm.args                 <- erlang vm args for the node
             + reltool.config              <- should have the install_upgrade.escript in overlay section


## Examples

Build a release and deploy it to your production hosts:

```sh
mix edeliver build release --branch=feature
mix edeliver deploy release to production
mix edeliver start production
```

Or execute the above steps with a single command:

```sh
mix edeliver update production --branch=feature --start-deploy
```

Build a *live* upgrade from v1.0 to v2.0 for a release and deploy it to production:

```sh
# build upgrade from tag v1.0 to v2.0

mix edeliver build upgrade --from=v1.0 --to=v2.0
mix edeliver deploy upgrade to production

# or if you have the old release in your release store,
# you can build the upgrade with that old release instead of the old git revision/tag

mix edeliver build upgrade --with=v1.0 --to=v2.0
mix edeliver deploy upgrade to production

# run ecto migrations manually:
mix edeliver migrate production
# or automatically during upgrade when upgrade is built with --run-migrations
```

The deployed upgrade will be **available immediately, without restarting** your application. If the generated [upgrade instructions (relup)](http://www.erlang.org/doc/man/relup.html) for the hot code upgrade are not sufficient, you can modify these files before installing the upgrade by using the `edeliver edit relup` command.

To execute that steps by a single command and upgrade e.g. all production nodes **automatically**  from their running version to the current version using **hot code upgrade** without restarting, you can use the `upgrade` command:

```
mix edeliver upgrade production
```

This performs the following steps automatically:

* Detect current version on all running nodes
* Validate that all nodes run the same version
* Build new upgrade from that version to the current version
* Auto-patch the relup file
* Deploy (hot code) upgrade while nodes are running
* Validate that all nodes run the upgraded version
* Deploy the release to not running nodes


---


## LICENSE

(The MIT license)

Copyright (c) Gerhard Lazu

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



