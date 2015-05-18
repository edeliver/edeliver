# **edeliver**

![edeliver logo](http://boldpoker.net/images/edeliver_500.png)

### Deployment for Elixir and Erlang

**edeliver** is based on [deliver](https://github.com/gerhard/deliver) and provides a **bash script to build and deploy Elixir and Erlang applications and perform hot-code upgrades**.

The **[erlang releases](http://www.erlang.org/doc/design_principles/release_handling.html)** are **built** on a **remote host** that have a similar configuration to the deployment target systems and can then be **deployed to several production systems**.

This is necessary because the **[release](http://www.erlang.org/doc/design_principles/release_handling.html) contains** the full **[erts (erlang runtime system)](http://erlang.org/doc/apps/erts/users_guide.html)**, all **[dependencies (erlang applications)](http://www.erlang.org/doc/design_principles/applications.html)**, native port drivers and **your own erlang application(s)** in a **standalone embedded node**.

Examples:

**Build** an erlang/elixir release **and deploy** it on your **production hosts**:

    ./edeliver build release --branch=feature
    ./edeliver deploy release to production
    ./edeliver start production


Build a **live upgrade** from v1.0 to v2.0 for an erlang/elixir release and deploy it to your production hosts:

    # build upgrade from tag v1.0 to v2.0

    ./edeliver build upgrade --from=v1.0 --to=v2.0
    ./edeliver deploy upgrade to production

    # or if you have the old release in your release store,
    # you can build the upgrade with that old release instead of the old git revision/tag

    ./edeliver build upgrade --with=v1.0 --to=v2.0
    ./edeliver deploy upgrade to production

The deployed upgrade will be **available immediately, without restarting** your application. If the generated [upgrade instructions (relup)](http://www.erlang.org/doc/man/relup.html) for the hot code upgrade are not sufficient, you can modify these files before installing the upgrade by using the `edit relup` command.


### Installation

Because it is based on [deliver](https://github.com/gerhard/deliver), is uses only shell scripts and has **no further dependencies** except the erlang / elixir build system.
It can be used with one of these build systems:


  * [rebar](https://github.com/basho/rebar) for pure erlang releases
  * [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) in conjunction with [exrm](https://github.com/bitwalker/exrm) for elixir/erlang releases
  * [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) in conjunction with [relx](https://github.com/erlware/relx) for elixir/erlang releases

Edeliver tries to autodetect which system to use to compile the sources and build the release:

  * If a `./mix.exs` file exists, [mix](http://elixir-lang.org/getting_started/mix/1.html) is used fetch the dependencies, compile the sources and [exrm](https://github.com/bitwalker/exrm) is used to generate the releases / upgrades.
  * If a `./relx.config` file exists in addition to a `./mix.exs` file, [mix](http://elixir-lang.org/getting_started/mix/1.html) is used fetch the dependencies, compile the sources and [relx](https://github.com/erlware/relx) is used to generate the releases / upgrades.
  * Otherwise [rebar](https://github.com/basho/rebar) is used to fetch the dependencies, compile the sources and generate the releases / upgrades.

This can be overridden by the config variables `BUILD_CMD=rebar|mix` and `RELEASE_CMD=rebar|mix|relx`.

If using [mix](http://elixir-lang.org/getting_started/mix/1.html), add it to you `mix.exs` config:

    defp deps do
        [{ :edeliver, github: "boldpoker/edeliver", compile: "mkdir -p ebin && cp src/edeliver.app.src ebin/edeliver.app" } ]
    end

And run `mix do deps.get, deps.compile`. Edeliver is then available as __mix task__: `mix edeliver`.

When using rebar, edeliver can be added as [rebar](https://github.com/basho/rebar) depencency. Just add it to your `rebar.config` (and ensure that a `./rebar` binary/link is in your project directory:

    {deps, [
      % ...
      {edeliver, "1.0",
        {git, "git://github.com/boldpoker/edeliver.git", {branch, master}}}
    ]}.


And link the `edeliver` binary to the root of your project directory:

    ./rebar get-deps # when using rebar, or ...
    ln -s ./deps/edeliver/bin/edeliver .

### Configuration

Create a `.deliver` directory in your project folder and add the `config` file:

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


It uses ssh and scp to build and deploy the releases. Is is **recommended** that you use ssh and scp with **keys + passphrase** only. You can use `ssh-add` if your don't want to enter your passphrase every time.

Maybe it is required to __configure git on your build host__ (git user name / email) or to clone the repository initially at the `BUILD_AT` path. And of course you need to __install [erlang](http://www.erlang.org/) and [elixir](http://elixir-lang.org/)__ on the `BUILD_HOST`. If you use mix to build the releases, you should __install [hex](https://hex.pm)__ on the build hosts before the first build (otherwise mix asks interactively to install it). Run the build command with __`--verbose`__ if it fails the first time.

There are **four kinds of commands**: **build commands** which compile the sources and build the erlang release **on the remote build system**, **deploy commands** which deliver the built releases to the **remote production systems**, **node commands** that **control** the nodes (e.g. starting/stopping) and **local commands**.

### Build Commands

The releases must be built on a system that is similar to the target system. E.g. if you want to deploy to a production system based on linux, the release must also be built on a linux system. Furthermore the [erlang runtime / OPT version](http://www.erlang.org/download.html) (e.g. OTP 17.5) of the remote build system is included into the release built and delivered to all production system. It is not required to install the otp runtime on the production systems.
For build commands the following **configuration** variables must be set:

- `APP`: the name of your release which should be built
- `BUILD_HOST`: the host where to build the release
- `BUILD_USER`: the local user at build host
- `BUILD_AT`: the directory on build host where to build the release. must exist.

The built release it then **copied to your local directory** `.deliver/releases` and can then be **delivered to your production servers** by using one of the **deploy commands**.

If compiling and generating the release build was successful, the release is **copied from the remote build host** to the **release store**. The default release store is the __local__ `.deliver` __directory__ but you can configure any destination with the `RELEASE_STORE=` environment variables, also __remote ssh destinations__ (in your server network) like `RELEASE_STORE=user@releases.acme.org:/releases/` or **amazon s3** locations like `s3://AWS_ACCESS_KEY_ID@AWS_SECRET_ACCESS_KEY:bucket`. The release is copied from the remote build host using the `RELEASE_DIR=` environment variable. If this is not set, the default directory is found by finding the subdirectory that contains the generated `RELEASES` file and has the `$APP` name in the path. e.g. if `$APP=myApp` and the `RELEASES` file is found at `rel/myApp/myApp/releases/RELEASE` the `rel/myApp/myApp` is copied to the release store.

#### Build Initial Release

    ./edeliver build release [--revision=<git-revision>|--tag=<git-tag>] [--branch=<git-branch>]

Builds an initial release that can be deployed to the production hosts. If you want to build a different tag or revision, use the `--revision=` or the `--tag` argument. If you want to build a different branch or the tag / revision is in a different branch, use the `--branch=` arguemtn.

#### Generate and Edit Upgrade Files (appup)

    ./edeliver build appups --from=<git-tag-or-revision>|--with=<release-version-from-store>
                           [--to=<git-tag-or-revision>] [--branch=<git-branch>]

Builds [release upgrade files (appup)](http://www.erlang.org/doc/man/appup.html) with instructions how to load the new code when an upgrade package is built. If your application __isn't used as dependency / library__ for other applications, you might __just__ want to __edit the final relup file__ as described later. The appup files are generated between two git revisions or tags or from an old revision / tag to the current master branch. Requires that the `--from=` parameter is passed at the command line which referes the the old git revision or tag to build the appup files from. If an **old release exists** already **in the release store**, it can be used by passing the old release number to the `--with=` argument. In that case the **building the old release** from the previous git revision **can be skipped**. The **generated appup files will be copied** to the `appup/OldVersion-NewVersion/*.appup` directory in your release store. You can **modify the generated** appup **files of your applications**, and delete all upgrade files of dependend apps or also of your apps, if the generated default upgrade script is sufficient. These files will be **incuded when the upgrade is built** with the `build upgrade` command and **overwrite the generated default appup files**.

#### Build an Upgrade Package for Live Updates of Running Nodes

    ./edeliver build upgrade --from=<git-tag-or-revision>|--with=<release-version-from-store>
                            [--to=<git-tag-or-revision>] [--branch=<git-branch>]

Builds a release upgrade package that can be deployed to production hosts with running nodes. The upgrade is generated between two git revisions or tags or from an old revision / tag to the current master branch. Requires that the `--from=` argument passed at the command line which referes the the old git revision or tag to build the upgrade from and an optional `--to=` argument, if the upgrade should not be created to the latest version. If an **old release exists** already **in the release store**, it can be used by passing the old release number to the `--with=` argument. In that case the **building the old release** from the previous git revision **can be skipped** (and build is faster). For the live upgrade process, you can **provide custom application upgrade files [(appup)](http://www.erlang.org/doc/man/appup.html)** as described in the previous section, or __modify the generated final upgrade instructions ([relup](http://www.erlang.org/doc/man/relup.html))__ as described in the next section (more convenient).


#### Edit the final upgrade instructions (relup)

    ./edeliver edit relup [--version=<upgrade-version>]

From the appup instructions of all included and updated applications, a __[relup](http://www.erlang.org/doc/man/relup.html)__ file is generated during the `build upgrade` command and included in the upgrade package. It contains the final upgrade instructions for the new release version. If there are __dependencies between applications__, it might be necessary to __modify this file__, e.g. changing the order of the applications or modules that are reloaded. Also if you don't want to reuse the appups for other releases, __it is much more convenient__ to modify this file instead of the appups which must be generated in a special step before.

#### Build Restrictions

To build **upgrades** it is required that there is **only one release** in the release directory (`rel`) of you project **configured** in your `rebar.config`. E.g. if you want to build two different releases `project-dir/rel/release_a` and `project-dir/rel/release_b` you need two `rebar.config` files that refer only to either one of that release directories in the `sub_dirs` section.
You can then pass the config file to use by setting the environment `REBAR_CONFIG=` at the command line.
The reason for that is, that when the upgrade is build with rebar, rebar tries to find the old version in both release directories.

### Deploy Commands

    ./edeliver deploy release|upgrade [[to] staging|production] [--version=<release-version>] [Options]

Deploy commands **deliver the builds** (that were created with a build command before) **to** your staging or **prodution hosts** and can perform the **live code upgrade**. The releases or upgrades to deliver are then available in your local directory `.deliver/releases`. To deploy releases the following **configuration** variables must be set:

- `APP`: the name of your release which should be built
- `PRODUCTION_HOSTS`: the production hosts to deploy to, separated by space
- `PRODUCTION_USER`: the local users at the production hosts
- `DELIVER_TO`: the directory at the production hosts to deploy the release at

- `STAGING_HOSTS`: the staging hosts to test the releases at, separated by space
- `STAGING_USER`: the local users at the staging hosts
- `TEST_AT`: the directory at the staging hosts. if not set, the DELIVER_TO is used as directory

Deploying to **staging** can be used to test your releases and upgrades before deploying them to the production hosts. If you don't pass the `[to] production` argument deploying to **staging is the default**.


#### Deploy an Initial / Clean Release

Deploys an initial release at the production hosts.
Requires that the `build release` command was executed before.
If there are several releases in the release store, you will be asked which release to deploy or you can pass the version by the `--version=` argument variable. If the nodes on the remote deploy hosts are up, the running old release is not affected. The new release will be **available** only after **starting or restarting** the nodes on the deploy hosts.


#### Deploy an Upgrade Package for Live Updates at Running Nodes

Deploys an upgrade at the production hosts and **upgrades the running nodes** to the new version.
Requires that the `build upgrade` command was executed before and that there is already an initial release deployed to the production hosts and that the node is running.

Release archives in your release store that were created by the `build release` command **cannot be used to deploy an upgrade**.

This comand requires that your release start script was **generate** by a **recent rebar version** that supports the `upgrade` command in addition to the `start|stop|ping|attach` commands. Releases generated with [mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) and [exrm](https://github.com/bitwalker/exrm) always contain the `upgrade` command.

If using rebar, make sure that the [install_upgrade.escript](https://github.com/basho/rebar/blob/master/priv/templates/simplenode.install_upgrade.escript) file which was generated by rebar is included in your release. So ensure, that the following line is in your `reltool.config`:

    {overlay, [ ...
           {copy, "files/install_upgrade.escript", "bin/install_upgrade.escript"}
    ]}.


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



### Extended Options

If something goes wrong, retry with the `--verbose` option.

If you have large release files that may be delivered to some of the deploy hosts already or if you want to deploy an old version again, you can skip the copy process by passing the `--skip-existing` option. edeliver checks then whether the release file exist already and have equal md5 checksum.



---

### LICENSE

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



