### Using Auto-Versioning

edeliver provides a way to automatically __increment__ the current __version__ for the __current build__ or to __append__ the __git commit count__ and/or __revision__ as [version metadata](http://semver.org/#spec-item-10).
__Using a different version for each release is essential__ especially if you build hot code __upgrades__, but also makes sense to see wich version is running, e.g. when using `mix edeliver version [staging|production]`.

Notice: This feature cannot be used in conjunction with the `--skip-mix-clean` command line option or the `SKIP_MIX_CLEAN=true` config respectively*.

##### Append git commit count and/or revision to the release version

```sh
  mix release.version show
  1.0.0
  mix edeliver build release --auto-version=commit-count
  # creates version 1.0.0+3027
  mix edeliver build upgrade --auto-version=git-revision
  # creates version 1.0.0+82a5834
  mix edeliver build upgrade --auto-version=commit-count+git-revision
  # creates version 1.0.0+3027-82a5834
  mix edeliver build upgrade --auto-version=git-revision+commit-count
  # creates version 1.0.0+82a5834-3027
```

##### Append other metadata: git branch or build date

```sh
  mix release.version show
  1.0.0
  mix edeliver build release --auto-version=git-branch
  # creates version 1.0.0+master
  mix edeliver build upgrade --auto-version=build-date
  # creates version 1.0.0+20160414
  mix edeliver build upgrade --auto-version=git-revision+build-date
  # creates version 1.0.0+82a5834-20160414
```

##### Append metadata to version permanentely

To append metadata permanentely you can set the `AUTO_VERSION` configuration variable in your `.deliver/config` file. This can be overridden by the `--auto-version=` command line argument.

```
 # ./deliver/config
 AUTO_VERSION=commit-count+git-revision
```


##### Increment / Set Version for the current release / upgrade

```sh
  mix release.version show
  1.2.3
  mix edeliver build release --increment-version=patch
  # creates version 1.2.4
  mix edeliver build release --increment-version=minor
  # creates version 1.3.0
  mix edeliver build release --increment-version=minor
  # creates version 2.0.0
  mix edeliver build release --set-version=1.3.0-beta.1
  # creates version 1.3.0-beta.1

```

`--increment-version=` and `--set-version=` can be used in conjunction with the `--auto-version=` option. The `AUTO_VERSION` default is also used unless the `--auto-version=` overrides it.

##### Use the Auto-Versioning / Increment-Version mix task locally

You can also use the auto versioning mix task provided by edeliver locally on your development machine, e.g. when testing your release / upgrade. The argument names to append metadata differ slightly and contain an `append-` prefix. If version modifiers are combined, they must be separated by a space.
It is required to clean the build output before* and to run the `release.version` and `release` mix tasks together using the `mix do` task while running the `release.version` task before the `release` task.

```sh
  mix release.version show
  1.2.3
  mix do clean, release.version increase major revision branch --dry-run
  Would update version from 1.2.3 to 2.0.0+82a5834-test
  # prints only the info above. You can always ommit the 'append-git-' part.
  mix do clean, release.version append-git-revision, release
  # creates version 1.2.3+82a5834
  mix do clean, release.version append-commit-count append-git-revision append-git-branch, release
  # creates version 1.2.3+3027-82a5834-master
  mix do clean, release.version increase major, release
  AUTO_VERSION="append-git-revision" mix do clean, release.version set 1.3.0-beta.1, release
  # creates version 1.3.0-beta.1+82a5834
```

(*) The build files must be removed to ensure that the `your_app.app` file will be (re-)generated with the new version.