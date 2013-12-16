### What's new in deliver 0.7.0

* **shared** strategy with file permissions support (think www-data,
  php-fpm, etc.)
* **s3** strategy for deploying your website to an S3 bucket (thanks
  @TheDeveloper)
* reset remotes to specific **REVISION** (see `deliver check`)
* configurable **GIT_PUSH** (--all, --mirror, --tags etc.)
* bluepill & smf support (thanks @jedahan)
* `-p|--plain` mode, as in no colours, great for CIs such as Jenkins

#### Notices

BRANCH has been replaced with REFSPEC.


### What's new in deliver 0.6.0

* **generated** strategy with built-in support for ROCCO. Other
  generators (including Jekyll or Octopress) are supported via
**GENERATE\_CMD**.
* automatically handles host authorization. On the initial deliver, if the
  hosts were not in `~/.ssh/known\_hosts`, they had to be allowed
manually, via the prompt. This is OK for local enviroments, but would
not work for CI.
* handles remote host authorization explicitly, via
  **AUTHORIZED\_REMOTE\_HOSTS** (think private npm modules &amp; private
  ruby gems, self-hosted)
* pre &amp; post hooks for the most common functions (eg.
  `pre_init_app_remotely`, `post_launch` etc.)

Thanks to Dan Palmer, there's now a [deliver chef cookbook][1], perfect
if you want to have your CI take code into production. This makes it
very easy to turn your Jenkins into a continous delivery system, just
add `deliver --verbose` to your build command.

#### Deprecations

REMOTE has been removed.

#### Notices

SERVERS has been replaced with HOSTS.



### What's new in deliver 0.5.0

* multi-host capable, leveraging bash jobs for parallel execution
* ability to deliver specific git branches (used to be only master)
* `deliver check` command which ensures that deliver has everything it
  needs to push the code remotely.  Good way of checking that the
  correct configs have been applied.
* `deliver -h|--help` for a summary of commands, modes and options.
* every time deliver runs, it logs all commands to
  `/tmp/deliver-[app-name]`
* now handling SSH timeouts and interrupts (think Ctrl+C)
* automatic github.com host key authentication when using git submodules

[1]: https://github.com/gchef/deliver-cookbook
