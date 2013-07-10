# **edeliver**  
### Build and Deployment System for Erlang Release Packages

**edeliver** is based on [deliver](https://github.com/gerhard/deliver) and provides a **bash script to build and deploy erlang releases and live upgrades**.

The **[erlang releases](http://www.erlang.org/doc/design_principles/release_handling.html)** are **built** on a **remote host** that have a similar configuration to the deployment target systems and can then be **deployed to several production systems**.

This is necessary because the **[release](http://www.erlang.org/doc/design_principles/release_handling.html) contains** the full **[erts (erlang runtime system)](http://erlang.org/doc/apps/erts/users_guide.html)**, all **[dependencies (erlang applications)](http://www.erlang.org/doc/design_principles/applications.html)**, native port drivers and **your own erlang application(s)** in a **standalone embedded node**.

Examples:

**Build** an erlang release **and deploy** it on your **production hosts**:

    ./edeliver build release --branch=feature 
    ./edeliver deploy release to production 
    ./edeliver start production


Build an live **upgrade** from v1.0 to v2.0 for an erlang release and deploy it on your production hosts:
    
    # optional: generate default appup upgrade files and edit them 
    
    ./edeliver build appups --from=v1.0 --to=v2.0  
    editor ./deliver/appups/v1.0.1-v1.0.2/*.appup  
    
    # build upgrade from tag v1.0 to v2.0
    
    ./edeliver build upgrade --from=v1.0 --to=v2.0 
    ./edeliver deploy upgrade to production
    
    # or if you have the old release in your release store, 
    # you can build the upgrade with that old release instead of the old git revision/tag
    
    ./edeliver build upgrade --with=v1.0 --to=v2.0
    ./edeliver deploy upgrade to production

The upgrade will be **available immediately, without restarting** your application. If the generated [application upgrade files (appup)](http://www.erlang.org/doc/man/appup.html) for the hot code upgrade are not sufficient, you can generate and modify these files before by using the `build appups` command.
    

### Installation

Because it is based on [deliver](https://github.com/gerhard/deliver) is uses only shell scripts and has **no further dependencies** except [rebar](https://github.com/basho/rebar) which should be present in your in the root of you project directory. 

It can be added as **[rebar](https://github.com/basho/rebar) depencency** for simple integration into erlang projects. Just add it to your `rebar.config`:

    {deps, [
      % ...
      {edeliver, "1.0",
        {git, "git://github.com/bharendt/edeliver.git", {branch, master}}}
    ]}.


And link the `edeliver` binary to the root of your project directory: 

    ./rebar get-deps
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

There are **four kinds of commands**: **build commands** which compile the sources and build the erlang release **on the remote build system**, **deploy commands** which deliver the built releases to the **remote production systems**, **node commands** that **control** the nodes (e.g. starting/stopping) and **local commands**.

### Build Commands

The releases must be built on a system that is similar to the target system. E.g. if you want to deploy to a production system based on linux, the release must also be built on a linux system. Furthermore the [erlang runtime / OPT version](http://www.erlang.org/download.html) (e.g. R16B) of the remote build system is included into the release built and delivered to all production system. It is not required to install the otp runtime on the production systems.
For build commands the following **configuration** variables must be set:

- `APP`: the name of your release which should be built
- `BUILD_HOST`: the host where to build the release
- `BUILD_USER`: the local user at build host
- `BUILD_AT`: the directory on build host where to build the release. must exist.

The built release it then **copied to your local directory** `.deliver/releases` and can then be **delivered to your production servers** by using one of the **deploy commands**.

If compiling and generating the release build was successful, the release is **copied from the remote build host** to the **release store**. The default release store is the local `.deliver` directory but you can configure any destination with the `RELEASE_STORE=` environment variables, also remote ssh destinations like `RELEASE_STORE=user@releases.acme.org:/releases/` or **amazon s3** locations like `s3://AWS_ACCESS_KEY_ID@AWS_SECRET_ACCESS_KEY:bucket`. The release is copied from the remote build host using the `RELEASE_DIR=` environment variable. If this is not set, the default directory is found by finding the subdirectory that contains the generated `RELEASES` file and has the `$APP` name in the path. e.g. if `$APP=myApp` and the `RELEASES` file is found at `rel/myApp/myApp/releases/RELEASE` the `rel/myApp/myApp` is copied to the release store.

#### Build Initial Release

    ./edeliver build release [--revision=<git-revision>|--tag=<git-tag>] [--branch=<git-branch>]

Builds an initial release that can be deployed to the production hosts. If you want to build a different tag or revision, use the `--revision=` or the `--tag` argument. If you want to build a different branch or the tag / revision is in a different branch, use the `--branch=` arguemtn. 

#### Generate and Edit Upgrade Files (appup)

    ./edeliver build appups --from=<git-tag-or-revision>|--with=<release-version-from-store> 
                           [--to=<git-tag-or-revision>] [--branch=<git-branch>]

Builds [release upgrade files (appup)](http://www.erlang.org/doc/man/appup.html) that perform the hot code loading when an upgrade is installed. The appup files are generated between two git revisions or tags or from an old revision / tag to the current master branch. Requires that the `--from=` parameter is passed at the command line which referes the the old git revision or tag to build the appup files from. If an **old release exists** already **in the release store**, it can be used by passing the old release number to the `--with=` argument. In that case the **building the old release** from the previous git revision **can be skipped**. The **generated appup files will be copied** to the `appup/OldVersion-NewVersion/*.appup` directory in your release store. You can (and should) then **modify the generated** appup **files of your applications**, and delete all upgrade files of dependend apps or also of your apps, if the generated default upgrade script is sufficient. These files will be **incuded when the upgrade is built** with the `build upgrade` command and **overwrite the generated default appup files**. 

#### Build an Upgrade Package for Live Updates of Running Nodes

    ./edeliver build upgrade --from=<git-tag-or-revision>|--with=<release-version-from-store> 
                            [--to=<git-tag-or-revision>] [--branch=<git-branch>]

Builds a release upgrade package that can be deployed to production hosts with running nodes. The upgrade is generated between two git revisions or tags or from an old revision / tag to the current master branch. Requires that the `--from=` argument passed at the command line which referes the the old git revision or tag to build the upgrade from and an optional `--to=` argument, if the upgrade should not be created to the latest version. If an **old release exists** already **in the release store**, it can be used by passing the old release number to the `--with=` argument. In that case the **building the old release** from the previous git revision **can be skipped**. To perform the live upgrade, you can **provide custom [application upgrade files (appup)](http://www.erlang.org/doc/man/appup.html)** that will be included in the release upgrade build if they exists in the release store at `appup/OldVersion-NewVersion/*.appup`. They will **overwrite the generated default appup files** See the `build appup` command for how to generated the default appup files and copy it to your release store.

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

Installs an initial release at the production hosts.
Requires that the `build release` command was executed before.
If there are several releases in the release store, you will be asked which release to install or you can pass the version by the `--version=` argument variable. If the nodes on the remote deploy hosts are up, the running old release is not affected. The new release will be **available** only after **starting or restarting** the nodes on the deploy hosts.


#### Deploy an Upgrade Package for Live Updates at Running Nodes

Installs an upgrade at the production hosts and **upgrades the running nodes** to the new version. 
Requires that the `build upgrade` command was executed before and that there is already an initial release deployed to the production hosts and that the node is running. 

Release archives in your release store that were created by the `build release` command **cannot be used to install an upgrade**.

This comand requires that your release start script was **generate** by a **recent rebar version** that supports the `upgrade` command in addition to the `start|stop|ping|attach` commands.

It also requires that the [install_upgrade.escript](https://github.com/basho/rebar/blob/master/priv/templates/simplenode.install_upgrade.escript) that was generated by rebar is included in your release. So make sure, that the folling line is in your `reltool.config`:

    {overlay, [ ...
           {copy, "files/install_upgrade.escript", "bin/install_upgrade.escript"}
    ]}.


### Recommended Project Structure


    your-app/                              <- project root dir
      + rebar                              <- rebar binary 
      + edeliver                           <- edeliver binary linking to deps/deliver/bin/deliver
      + rebar.config                       <- should have "rel/your-app" in the sub_dirs section
      + .deliver                           <- default release store
      |  + releases/*.tar.gz               <- the built releases / upgrade packages
      |  + appup/OldVsn-NewVsn/*.apppup    <- generated appup files
      |  + config                          <- deliver configuration
      + src/                               
      |  + *.erl
      |  + your-app.app.src
      + priv/
      + deps/
      |  + edeliver/
      + rel/
         + your-app/                       <- generated by `./rebar create-node nodeid=your-app`
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



