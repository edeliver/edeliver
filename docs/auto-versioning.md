### Using Auto-Versioning

edeliver provides a way to automatically __increment__ the current __version__ for the __current build__ and/or to __append__ the __git commit count__ and/or __revision__ as [version metadata](http://semver.org/#spec-item-10).
__Using a different versions for each release is essential__ especially if you build hot code __upgrades__, but also makes sense to see wich version is running, e.g. when using `mix edeliver version [staging|production]`.

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
  mix edeliver build release --auto-version=git-revision+git-branch-unless-master
  # creates version 1.0.0+82a5834
  mix edeliver build upgrade --auto-version=build-date
  # creates version 1.0.0+20160414
  mix edeliver build upgrade --auto-version=git-revision+build-date
  # creates version 1.0.0+82a5834-20160414
```

##### Append metadata to version permanentely

To append metadata permanentely you can set the `AUTO_VERSION` configuration variable in your `.deliver/config` file. This can be overridden by the `--auto-version=` command line argument.

```sh
 # ./deliver/config
 AUTO_VERSION=commit-count+git-revision+branch-unless-master
```

##### Available metadata which can be appended to the release version


  * `[git-]revision` Appends sha1 git revision of current HEAD.
  * `[git-]branch` Appends the current branch that is built.
  * `[git-]branch-unless-master` Appends the current branch that is built but only unless it is the master branch.
  * `[build-]date` Appends the build date as YYYYMMDD.
  * `[build-]time` Appends the build time as HHMMSS.
  * `[git-]commit-count[-all[-branches]` Appends the number of commits across all branches.
    Allows edeliver to detect which version is newer if it is appended as first metadata to
    the release version.
  * `[git-]commit-count-branch` Appends the number of commits from the current branch.
    This makes more sense, if the branch name is also appended as metadata to avoid
    conflicts from different branches.


Using __commit count accross all branches__ (`commit-count[-all[-branches]`) __or__ using the __build date__ (`[build-]date`) __as first metadata__ to append, enables edeliver to __consider__ that values __when sorting__ versions. Using `[git-]revision` or commit count for the current branch in conjunction with the branch name (`commit-count-branch+branch`) enables you to __uniquely identify__ the built/deployed __version__. If the revision is used, __edeliver can display the commit message for that version__ (and the 5 previous commit messages) if `edeliver version [staging|production]` is used. To achieve both (sorting and identifying versions) and to see whether a feature branch is built/deployed, the following permanent auto-versioning option is recommended: `AUTO_VERSION=commit-count+git-revision+branch-unless-master`.


For more information also try `mix edeliver help upgrade`, `mix edeliver help release` or `mix help release.version`.

Example Output for `edeliver version` task if `git-revision` is used for auto-versioning:

```sh
$ mix edeliver version production

EDELIVER YOUR_APP WITH VERSION COMMAND

-----> getting release versions from production servers

production node: 0

  user    : production
  host    : host-01.domain.net
  path    : /your/deploy/path
  response: 1.2.3+4915-e834c67
  branch  : master
  revision: e834c67
  date    : 2016-04-19 17:10:13 (git commit)
  commits : Use autoversion for edeliver
            Update release version to 1.2.3
            Revert something
            Add something
            ...


production node: 1

  user    : production
  host    : host-12.domain.net
  path    : /your/deploy/path
  response: 1.2.3+4931-4805b65
  branch  : feature
  revision: 4805b65
  date    : 2016-04-21 16:41:01 (git commit)
  commits : Add another feature
            Add new feature
            Use autoversion for edeliver
            Update release version to 1.2.3
            Revert something
            Add something
            ...


VERSION DONE!
```

Then number of commits can be adjusted by the `VERSION_INFO_LAST_COMMITS` env / config.

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

You can also use the auto versioning mix task provided by edeliver locally on your development machine, e.g. when testing your release / upgrade. The argument names to append metadata differ slightly and contain an (optional) `append-` prefix. If version modifiers are combined, they can be separated by a space (or by the `+` character as for the edeliver option).
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
