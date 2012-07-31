### What's new in deliver 0.6.0

Thanks to Dan Palmer, there's now a [deliver chef cookbook][1], perfect
if you want to have your CI take code into production. This makes it
very easy to turn your Jenkins into a continous delivery system, just
add `deliver --verbose` to your build command.

* handles remote host authorization explicitly, via
  AUTHORIZED\_REMOTE\_HOSTS (think private npm modules &amp; private
  ruby gems, self-hosted)
* pre & post hooks for the most common functions (eg.
  `pre_init_app_remotely` &amp; `post_launch`)

#### Deprecations

REMOTE has been removed.


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
