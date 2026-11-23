---
name: code-review.check.cli-options-and-docs
description: Catch command-line options, config variables and commands that are added or changed without being wired up and documented everywhere users find them.
---

# Options, config and docs

## When to run

When the PR adds, removes or renames a command, a `--option`, or a variable that
users set in `.deliver/config`, or changes their defaults.

## Checklist

- [ ] A new `--option` is parsed in `libexec/erlang-init` and listed in the help
      text of every command that accepts it (`edeliver help <command>`)
- [ ] Options that cannot be combined are rejected with `error_message` and exit
      status 2, like `--set-version` with `--skip-mix-clean` in `libexec/erlang-init`
- [ ] A command or option usable through Mix is also listed in the moduledoc of
      `lib/mix/tasks/edeliver.ex`
- [ ] A new `.deliver/config` variable has a default (`libexec/defaults` or
      `__default_app_config` in `libexec/core`), or is added to `REQUIRED_CONFIGS`
      so `__check_config` rejects a config without it
- [ ] Options that can be set permanently are listed in `guides/configuration.md`
      ("Use edeliver Options Permanently"), and new required config in its first table
- [ ] Behaviour users notice is described in `README.md` or the matching guide
      (`guides/docker.md`, `guides/auto-versioning.md`, `guides/relup-patching.md`)
- [ ] `CHANGELOG.md` has an entry under the next version, in the existing
      Enhancements / Fixes / Backwards incompatible changes format
- [ ] A removed or renamed option or variable keeps working with a warning
      (`__add_to_deprecations` in `libexec/deprecations`) instead of failing for
      existing configs, or is listed under "Backwards incompatible changes"
- [ ] New files needed at runtime are included in `package: files` in `mix.exs`,
      or they are missing from the Hex package (see CHANGELOG 1.9.2)

## Severity guidance

| Finding | Severity |
|---|---|
| Option or variable renamed or removed without deprecation | Major |
| Runtime file missing from the Hex package | Major |
| Option parsed but not in help text or docs | Minor |
| Missing CHANGELOG entry | Minor |

## Do not flag when

- the PR only changes internal `__` helpers with no user-visible effect
- the PR only fixes typos or formatting in docs
- a CHANGELOG entry is missing on a PR that only touches CI or tests
