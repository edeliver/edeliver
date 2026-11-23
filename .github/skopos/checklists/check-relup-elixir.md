---
name: code-review.check.relup-elixir
description: Catch changes to the Elixir relup and Distillery code that break hot-code upgrades or the public behaviours users implement.
---

# Relup modifications and Elixir code

## When to run

When the PR changes files under `lib/`, `src/` or `mix.exs`.

## Checklist

- [ ] Public behaviours and their callbacks stay compatible:
      `Edeliver.Relup.Modification`, `Edeliver.Relup.Instruction` and
      `Edeliver.Relup.RunnableInstruction` are implemented in user projects
      (`guides/relup-patching.md`)
- [ ] The priority rules in `Edeliver.Relup.Modification` still hold: user
      modifications win over the defaults, and `--relup-mod` / `--skip-relup-mod`
      still select or skip them
- [ ] Every new up-instruction has a matching down-instruction, or the PR says
      why a downgrade is not possible
- [ ] Code that runs inside the upgrading node (runnable instructions) only calls
      modules that are loaded in the old release; it cannot rely on new code yet
- [ ] Processes are resumed on every path after they are suspended, including
      errors and timeouts (`suspend_*` / `resume_*` instructions)
- [ ] Distillery stays optional: code outside `lib/distillery/` does not reference
      `Distillery.*` modules, and `lib/distillery/` checks with
      `Code.ensure_loaded?` where the existing plugins do
- [ ] Code compiles on the oldest supported Elixir in `mix.exs` (`>= 1.10.0`);
      no newer standard library functions without a fallback
- [ ] New `.ex` files are under a path listed in `elixirc_paths/0` in `mix.exs`
- [ ] New `@doc` / `@moduledoc` and `@spec` match the existing modules, since
      they are published on HexDocs
- [ ] Bash helpers called from Elixir tests (`test/test_helper.exs`) still have
      the tested names and output; tests are updated with the code

## Severity guidance

| Finding | Severity |
|---|---|
| Upgrade can leave processes suspended or the node in a broken state | Critical |
| Breaking change to a public behaviour or callback | Major |
| Hard dependency on Distillery, or code that does not compile on Elixir 1.10 | Major |
| Missing down-instruction without explanation | Major |
| Missing or outdated `@doc` / `@spec` | Minor |

## Do not flag when

- formatting differs from `mix format` in lines the PR does not touch
- a change only affects `test/` or `test/configs/` sample projects
