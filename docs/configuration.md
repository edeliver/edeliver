# Configuration (.deliver/config)


### Required Configuration

This options can or must be set in the `.deliver/config` file to configure edeliver:

| environment variable   | required | info                                           |
|------------------------|----------|------------------------------------------------|
| `APP`                  |      yes | the lower case name of your app                |
| `BUILD_AT`             |      yes | the directory on the build host to build at    |
| `BUILD_CMD`            |       no | tool used to build sources. (mix\|rebar)        |
| `BUILD_HOST`           |      yes | the host to build at                           |
| `BUILD_USER`           |      yes | the ssh user for the host to build at          |
| `DELIVER_TO`           |      yes | the directory on production hosts to deploy to |
| `GIT_CLEAN_PATHS`      |       no | don't clean everything when building           |
| `PRODUCTION_HOSTS`     |      yes | the production hosts to deploy to              |
| `PRODUCTION_USER`      |      yes | the ssh user for the production hosts          |
| `RELEASE_CMD`          |       no | tool used to build release. (mix\|relx\|rebar)   |
| `USING_DISTILLERY`     |       no | use distillery instead of exrm (experimental)  |
| `STAGING_HOSTS`        |       no | the staging hosts to deploy to                 |
| `STAGING_USER`         |       no | the ssh user for the staging hosts             |
| `TEST_AT`              |       no | the directory on staging hosts to deploy to    |

See also [Configuration Section](https://github.com/boldpoker/edeliver#user-content-configuration) in the [README](https://github.com/boldpoker/edeliver/blob/master/README.md).

### Use edeliver Options Permanentely

This options can be set in the `.deliver/config` file to use the command line option permanentely without passing them every time:


| environment variable in config file   | edeliver argument    | info                                          |
|---------------------------------------|----------------------|-----------------------------------------------|
| `AUTO_VERSION=...`                    | `--auto-version=...` | append metadata to version                    |
| `CLEAN_DEPLOY=boolean`                | `--clean-deploy`     | remove data from old releases                 |
| `FORCE=boolean`                       | `--force`            | don't ask                                     |
| `RELUP_MODIFICATION_MODULE=...`       | `--relup-mod=...`    | specify module to modify relups automatically |
| `SKIP_GIT_CLEAN=boolean`              | `--skip-git-clean`   | don't clean anything when building            |
| `SKIP_MIX_CLEAN=boolean`              | `--skip-mix-clean`   | don't clean compiled output when building     |
| `SKIP_RELUP_MODIFICATIONS=boolean`    | `--skip-relup-mod`   | don't modify relup automaticaly               |
| `START_DEPLOY=boolean`                | `--start-deploy`     | (re-) start node(s) after deploy              |
| `TARGET_MIX_ENV=prod\|dev\|...`       | `--mix-env=...`      | build with custom `MIX_ENV`                   |

Passing any of that arguements to edeliver overrides the value set in the config file.
Try also `edeliver help build release`, `edeliver help build upgrade` or `edeliver help deploy release` for more information.

### Additional Envirionment Variables available in config file


This environment variables are set by edeliver and can be used `.deliver/config` file to adjust something:


| environment variable  | possible values         |
|-----------------------|-------------------------|
| `$MODE`               | `verbose|compact|debug` |
| `$VERBOSE`            | `true|false`            |
| `$SILENCE`            | `true|false`            |
| `$DEPLOY_ENVIRONMENT` | `staging|production`    |
| `$NODE_ENVIRONMENT`   | `staging|production`    |

See also [Extend edeliver (config) to fit your needs](https://github.com/boldpoker/edeliver/wiki/Extend-edeliver-(config)-to-fit-your-needs) to see some use cases.
