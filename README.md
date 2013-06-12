## Erlang release build and deployment system

This is a fork of [deliver](https://github.com/gerhard/deliver) providing **[strategies](https://github.com/gerhard/deliver/tree/master/strategies) to build and deploy erlang releases**.

The **[erlang releases](http://www.erlang.org/doc/design_principles/release_handling.html)** are **built** on a **remote host** that have a similar configuration as the deployment target system and can then be **deployed to several production systems**.

This is necessary because the [release](http://www.erlang.org/doc/design_principles/release_handling.html) contain the full [erts (erlang runtime system)](http://erlang.org/doc/apps/erts/users_guide.html), all [dependencies (erlang applications)](http://www.erlang.org/doc/design_principles/applications.html) and your own erlang application(s) in a **standalone embedded node**.

Examples:

**Build** an erlang release **and deploy** it on your **production hosts**:

    STRATEGY=erlang-build-release ./deliver 
    STRATEGY=erlang-install-release ./deliver 

Build an **update** from v1.0 to v2.0 for an erlang release and deploy it your production hosts.
The update will be **available after restart** of your application.

    STRATEGY=erlang-build-update FROM=v1.0 TO=v2.0 ./deliver 
    STRATEGY=erlang-install-update VERSION=v2.0 ./deliver 
    STRATEGY=erlang-restart-apps ./deliver 
    
Build an **upgrade** from v1.0 to v2.0 for an erlang release and deploy it your production hosts.
The upgrade will be **available immediately, without restarting** your application. It requires to
add [application upgrade files (appup)](http://www.erlang.org/doc/man/appup.html) to the new version.

    STRATEGY=erlang-build-upgrade FROM=v1.0 TO=v2.0 ./deliver 
    STRATEGY=erlang-install-upgrade VERSION=v2.0 ./deliver 
    

### Installation

Because it is based on [deliver](https://github.com/gerhard/deliver) is uses only shell scripts and has **no further dependencies** except [rebar](https://github.com/basho/rebar) which should be in your `$PATH` or in the root of you project directory. 

It can be added as **[rebar](https://github.com/basho/rebar) depencency** for simple integration into erlang projects. Just add it to your `rebar.config`:

    {deps, [
      % ...
      {deliver, "0.7.0",
        {git, "git://github.com/bharendt/deliver.git", {branch, master}}}
    ]}.


And link the `deliver` binary to the root of your project directory: 

    ./rebar update-deps get-deps
    ln -s ./deps/deps/deliver/bin/deliver .
    
### Configuration
    
Create a `.deliver` directory in your project folder and add the `config` file:

    #!/usr/bin/env bash
    
    APP="your-erlang-app" # name of your release
    STRATEGY="erlang" # default strategy. shows build and deploy strategies
    
    BUILD_HOST="build-system.acme.org" # host where to build the release
    BUILD_USER="build" # local user at build host
    BUILD_AT="/tmp/deliver-builds" # build directory on build host
    
    HOSTS="deploy-host1.acme.org,deploy-host2.acme.org" # deploy hosts
    APP_USER="production" # local user at deploy hosts
    DELIVER_TO="/opt/my-erlang-app" # deploy directory on

There are **two kinds of strategies**: **build strategies** which compile the sources and build the erlang release **on the remote build system** and **deploy strategies** which deliver the built releases to the **remote production systems**.

### Build Strategies

The releases must be built on a system that is similar to the target system. E.g. if you want to deploy to a production system based on linux, the release must also be built on a linux system. Furthermore the [erlang runtime / OPT version](http://www.erlang.org/download.html) (e.g. R16B) of the remote build system is included into the release built and delivered to all production system. It is not required to install the otp runtime on the production systems.
For build strategies the following **configuration** variables must be set:

- `APP`: the name of your release which should be built
- `BUILD_HOST`: the host where to build the release
- `BUILD_USER`: the local user at build host
- `BUILD_AT`: the directory on build host where to build the release. must exist.

The built release it then **copied to your local directory** `.deliver/erlang-releases` and can then be **delivered to your production servers** by using one of the **deploy strategies**.

If compiling and generating the release build was successful, the release is **copied from the remote build host** to the **release store**. The default release store is the `.deliver/erlang-releases` but you can configure any destination with the `RELEASE_STORE=` environment variables, also remote destinations like `RELEASE_STORE=user@releases.acme.org:/releases/`. The release is copied from the remote build host using the `RELEASE_DIR=` environment variable. If this is not set, the default directory is found by finding the subdirectory that contains the generated `RELEASES` file and has the `$APP` name in the path. e.g. if `$APP=myApp` and the `RELEASES` file is found at `rel/myApp/myApp/releases/RELEASE` the `rel/myApp/myApp` is copied to the release store.

#### erlang-build-release

Builds an initial release that can be deployed to the production hosts. If you want to build a different tag or revision, use the `REVISION=` environment variable. If you want to bild a different branch or the tag / revision is in a different branch, use the `BRANCH=` variable. 

#### erlang-build-update

Builds a release update that can be deployed to the production hosts. The update is generated for two git revisions or tags or from an old revision / tag to the current master branch. Requires that a `FROM=` environment variable is passed at the command line which referes the the old git revision or tag to build the update from and an optional `TO=` variable, if the update should not be created to the latest version.

#### erlang-build-upgrade

Builds a release upgrade that can be deployed to production hosts with running nodes. The upgrade is generated for two git revisions or tags or from an old revision / tag to the current master branch. Requires that a `FROM=` environment variable is passed at the command line which referes the the old git revision or tag to build the upgrade from and an optional `TO=` variable, if the upgrade should not be created to the latest version.To perform the live upgrade, it is required that [application upgrade files (appup)](http://www.erlang.org/doc/man/appup.html) exist, that will be included in the release upgrade build.

#### build restrictions

To build **updates or upgrades** it is required that there is **only one release** in the release directory (`rel`) of you project **configured** in your `rebar.config`. E.g. if you want to build two different releases `project-dir/rel/release_a` and `project-dir/rel/release_b` you need two `rebar.config` files that refer only to either one of that release directories in the `sub_dirs` section.
You can then pass the config file to use by adding the environment `REBAR_CONFIG=` at the command line.
The reason for that is, that if the update or upgrade is build with rebar, rebar tries to find the old version in both release directories.

### Deploy Strategies

Deploy strategies deploys the builds that were created with a build strategy before to your procution hosts. The releases, updates or upgrades to deliver are then available in your local directory `.deliver/erlang-releases`. To deploy a release the following **configuration** variables must be set:

- `APP`: the name of your release which should be built
- `HOSTS`: the production hosts to deploy to
- `APP_USER`: the local users at the production hosts
- `DELIVER_TO`: the directory at the production hosts to deploy the release at

#### erlang-install-release

Installs an initial release at the production hosts.
Requires that the _erlang-build-release_ strategy was executed before.
If there are several releases in the release store, you will be asked which release to install or you can pass the version by the `VERSION=` environment variable.


#### erlang-install-update

Installs an update at the production hosts. This does **not affect running nodes** on the production servers. The update is booted when the **production nodes are started the next time**. 
Requires that the _erlang-build-update_ strategy was executed before and that there is already an initial release deployed to the production hosts.

#### erlang-install-upgrade

Installs an updated at the production hosts and **upgrades the running nodes** to the new version.
Requires that the _erlang-build-upgrade_ strategy was executed before and that there is already an initial release deployed to the production hosts and that the node is running.

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



