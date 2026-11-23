---
name: code-review.check.shell-remote-commands
description: Catch quoting, escaping and portability bugs in the shell code that edeliver runs locally, over ssh and in docker.
---

# Shell and remote commands

## When to run

When the PR changes `bin/edeliver`, any file under `libexec/` or `strategies/`,
or `docker/start_container`.

## Checklist

- [ ] Command strings passed to `__remote`, `__sync_remote` or `__sync_local`
      (`libexec/core`) escape every variable that must expand on the remote host
      (`\$var`, `\"`), and leave unescaped only the values that must expand
      locally before ssh runs. Getting this wrong expands the wrong value silently
- [ ] Code that runs on deploy hosts, release stores or inside release containers
      is POSIX `sh`: no `[[ ]]`, arrays or `${var// }` there. Local code
      in `bin/edeliver` and `libexec/` may use bash (see commits 08b419a, 1435754)
- [ ] Remote command strings start with `[ -f $PROFILE ] && source $PROFILE` and
      `set -e` when later steps depend on earlier ones, like the existing jobs in
      `libexec/common`
- [ ] Variables holding paths, hosts, versions or user config are quoted
      (`"$DELIVER_TO"`), except where word splitting is intended, such as the
      host lists `$HOSTS` and `$HOSTS_APP_USER`
- [ ] Command output that callers parse stays clean: chatter goes through
      `status`, `hint_message` or is guarded by `$SILENCE` / `$VERBOSE`, so it does
      not end up in a value read with `$(…)`
- [ ] Failures stop the run with `error` / `error_message` and a message that
      names the host and the failing step; no new `|| true` or `|| :` hides a real
      failure
- [ ] New user hook points use `__exec_if_defined "pre_…"` / `"post_…"`
      (`libexec/core`), and existing hook names are not renamed or removed
      (users define them in `.deliver/config`)
- [ ] New private helpers use the `__` prefix; functions without it are public
      and may be overridden by users and strategies (`bin/edeliver` header)
- [ ] `rm -rf`, `mv` or `git clean` on remote hosts never run on an empty or
      unset variable (for example `rm -rf "$DELIVER_TO/$APP"` with `DELIVER_TO`
      empty)
- [ ] The change works for all build and release tools it touches: `mix`,
      `distillery`, `rebar3`, and `BUILD_HOST="docker"` where relevant

## Severity guidance

| Finding | Severity |
|---|---|
| Destructive command can run on an empty or wrong path | Critical |
| Variable expands on the wrong side of ssh, or bash-only syntax in remote `sh` code | Major |
| Failure is swallowed and the deploy reports success | Major |
| Hook removed or renamed without `__add_to_deprecations` or a CHANGELOG note | Major |
| Unquoted variable that cannot contain spaces in practice | Minor |

## Do not flag when

- bash-only syntax is used in code that only runs locally (`bin/`, `libexec/`
  outside the remote command strings)
- `$HOSTS`, `$HOSTS_APP_USER` or `$SILENCE` are left unquoted on purpose
- the style of untouched existing code differs; only review lines the PR changes
