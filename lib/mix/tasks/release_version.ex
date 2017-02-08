defmodule Mix.Tasks.Release.Version do
  use Mix.Task

  @shortdoc "Displays or modifies the release version"

  @moduledoc """
  Displays the release version or modifies it before building the release.

  This task can be used in conjunction with the `release` task to modify
  the version for the release / upgrade. The compiled files must be cleaned
  before and the release task must be executed after. Increasing version
  and appending metadata to the version can be combined, e.g:

  `mix do clean, release.version increment minor append-git-revision append-branch, release`

  To automatically append metadata, you can set the `$AUTO_VERSION` environment variable.

  # Usage:

    * `mix release.version show`
    * `mix do clean, release.version Append-Metadata... [Option], release`
    * `mix do clean, release.version increment [patch|minor|major] [version] [Append-Metadata...] [Option], release`
    * `mix do clean, release.version set <new-version> [Append-Metadata...] [Option], release`

  ## Append-Metadata

    * `[append-][git-]revision` Appends sha1 git revision of current HEAD
    * `[append-][git-]branch[-unless-master]` Appends the current branch that is built. If
      `-unless-master` is used, the branch is only appended unless it is the master branch.
    * `[append-][build-]date` Appends the build date as YYYYMMDD
    * `[append-][git-]commit-count[-all[-branches]|-branch]` Appends the number of commits
    * `[append-]mix-env` Appends the mix environment used while building the release
      from the current branch or across all branches (default).  Appending the commit count
      from the current branch makes more sense, if the branch name is also appended as metadata
      to avoid conflicts from different branches.

  ## Version Modification

    * `show` Displays the current release version.
    * `increment` Increments the release version for the current build
      - `patch` Increments the patch version (default). The last part of a tripartite version.
      - `minor` Increments the minor version. The middle part of a tripartite version.
      - `major` Increments the major version. The first part of a tripartite version.
    * `set <new-version>` Sets the release version for the current build

  ## Options

    * `-V`, `--verbose` Verbose output
    * `-Q`, `--quiet`   Print only errors while modifying version
    * `-D`, `--dry-run` Print only new version without changing it

  ## Environment Variables

    * `AUTO_VERSION` as long no arguments are passed directly which append metadata to the version
     (flags from the Append-Metadata section) the values from that env are used to append metadata.

  ## Example

    `MIX_ENV=prod mix do clean, release.version append-git-revision, release`
  """
  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    case OptionParser.parse(args, aliases: [V: :verbose, Q: :quiet, D: :dry_run], switches: [verbose: :boolean, quiet: :boolean, dry_run: :boolean]) do
      {switches, args, []} ->
        case parse_args(args) do
          {:modify, modification_functions} ->
            case Keyword.get(switches, :dry_run, false) do
              true ->
                {:modified, new_version} = modify_version({:modify, modification_functions}, old_version = get_version())
                Mix.Shell.IO.info "Would update version from #{old_version} to #{new_version}"
              false -> update_release_version(modification_functions, switches)
            end
          :show -> print_version()
          {:error, message} -> Mix.raise message
        end
      {_, _, [{unknown_option, _}]} -> Mix.raise "Error: Unknown argument #{unknown_option} for 'release.version' task."
      {_, _, unknown_options} ->
        unknown_options = unknown_options |> Enum.map(&(elem(&1, 0))) |> Enum.join(", ")
        Mix.raise "Error: Unknown arguments #{unknown_options} for 'release.version' task."
    end
  end

  # Sets the release version to the new value by using the passed update funs.
  @spec update_release_version(modification_functions::[modification_fun], options::[String.t]) :: new_version::String.t
  defp update_release_version(modification_functions, options) do
    {old_version, new_version} = Agent.get_and_update Mix.ProjectStack, fn(state) ->
      [root=%{config: config}|rest] = state.stack
      {old_version, new_version, config} = List.foldr config, {"","", []}, fn({key, value}, {old_version, new_version, config}) ->
        {old_version, new_version, value} = if key == :version do
          old_version = value
          {:modified, new_version} = modify_version({:modify, modification_functions}, old_version)
          value = new_version
          {old_version, new_version, value}
        else
          {old_version, new_version, value}
        end
        {old_version, new_version, [{key, value}|config]}
      end
      stack = [%{root|config: config}|rest]
      {{old_version, new_version}, %{state| stack: stack}}
    end
    debug "Changed release version from #{old_version} to #{new_version}", options
  end

  defp print_version() do
    Mix.Shell.IO.info get_version()
  end

  defp get_version() do
    Keyword.get(Mix.Project.config, :version)
  end

  defp update_version(old_version, :patch) do
    case String.split(old_version, ".") do
      [""] -> "0.0.1"
      [major] -> major <> ".0.1"
      [major, minor] -> major <> "." <> minor <> ".1"
      [major, minor, patch] ->
        patch = Regex.run(~r"^\d+", patch) |> List.first |> String.to_integer()
        major <> "." <> minor <> ".#{patch+1}"
    end
  end
  defp update_version(old_version, :minor) do
    case String.split(old_version, ".") do
      [""] -> "0.1.0"
      [major] -> major <> ".1.0"
      [major, minor|_] -> major <> "." <> "#{inspect String.to_integer(minor)+1}" <> ".0"
    end
  end
  defp update_version(old_version, :major) do
    case String.split(old_version, ".") do
      [""] -> "1.0.0"
      [major|_] -> "#{inspect String.to_integer(major)+1}" <> ".0.0"
    end
  end
  defp update_version(_old_version, version = <<_,_::binary>>) do
    version
  end

  defp debug(message, options) do
    if not quiet?(options) and verbose?(options) do
      Mix.Shell.IO.info message
    end
  end

  defp quiet?(options),   do: Keyword.get(options, :quiet, false)
  defp verbose?(options), do: Keyword.get(options, :verbose, false)


  @type modification_arg :: {modified_version::String.t, has_metadata::boolean}
  @type modification_fun :: ((modification_arg) -> modification_arg)

  @doc """
    Parses the arguments passed to this `release.version` task and merges them
    with the `AUTO_VERSION` environment variable. This arguments must not contain
    any output flags like `-V` or `-Q`.
  """
  @spec parse_args(OptionParser.argv) :: :show | {:error, message::String.t} | {:modify, [modification_fun]}
  def parse_args(args) do
    append_metadata_options = ["commit_count", "commit_count_branch", "revision", "date", "branch", "branch_unless_master", "mix_env"]
    update_version_options  = ["major", "minor", "patch", "set"]

    args = normalize_args(args)
    has_append_metadata_in_args? = Enum.any?(append_metadata_options, &(Enum.member?(args, &1)))
    {args, default_args} = if auto_version = System.get_env("AUTO_VERSION") do
      # if no arguments appending metadata exists, use the values from AUTO_VERSION env
      case OptionParser.split(auto_version) |> normalize_args() do
        default_args = [_|_] when not has_append_metadata_in_args? -> {args ++ default_args, default_args}
        default_args = [_|_] -> {args, default_args}
        _ -> {args, []}
      end
    else
      {args, []}
    end
    {version_to_set, args} = get_version_to_set_from_args(args, [])
    args = sort_args_append_metadata_last(args, [], [])
    known_options = update_version_options ++ append_metadata_options
    unknown_options = args -- known_options
    illegal_combinations = Enum.filter args, &(Enum.member?(update_version_options, &1))
    cond do
      args == ["show"] -> :show
      unknown_options == ["count"] -> {:error, "Unknown option 'count' for 'release.version' task.\nDid you mean 'commit-count'?"}
      Enum.count(unknown_options) == 1 -> {:error, "Unknown option #{Enum.join(unknown_options, " ")} for 'release.version' task."}
      Enum.count(unknown_options) > 1 -> {:error, "Unknown options for 'release.version' task: #{Enum.join(unknown_options, " ")}"}
      args == [] -> {:error, "No arguments passed to 'release.version' task and no AUTO_VERSION env is set."}
      Enum.count(illegal_combinations) > 1 -> {:error, "Illegal combination of options for 'release.version' task: #{Enum.join(illegal_combinations, " ")} can't be used together."}
      Enum.member?(args, "set") && (version_to_set == nil || Enum.member?(known_options, version_to_set)) -> {:error, "No version to set for 'release.version' task. Please add the version as argument after 'set' like: 'set 2.0.0-beta'."}
      Enum.any?(default_args, &(Enum.member?(illegal_combinations, &1))) ->  {:error, "Increasing major|minor|path or setting version is not allowed as default set in 'AUTO_VERSION' env for 'release.version' task."}
      true ->
        modification_functions = Enum.map args, fn(arg) ->
          case arg do
            "set" when version_to_set != nil -> &(modify_version_set(&1, version_to_set))
            _ -> String.to_atom("modify_version_" <> arg)
          end
        end
        {:modify, modification_functions}
    end
  end

  @doc """
    Normalizes the arguments passed to this task. This is done by
    splitting arguments separated by a `+`, removing leading `append-`
    `-git` and `-build` strings and renaming `commit-count` to
    `commit_count`
  """
  @spec normalize_args(OptionParser.argv) :: OptionParser.argv
  def normalize_args(args) do
    args |> List.foldr([], fn(arg, acc) ->
      if String.contains?(arg, "+") do
        String.split(arg, "+", trim: true) ++ acc
      else
        [arg | acc]
      end
    end)
    |> Enum.filter(&(&1 != "increment" && &1 != "version" && &1 != "increase" && String.strip(&1) != ""))
    |> Enum.map(fn(arg) ->
      case arg do
        "append-" <> command -> command
        command -> command
      end
    end) |> Enum.map(fn(arg) ->
      case arg do
        "git-" <> command -> command
        "build-" <> command -> command
        command -> command
      end
    end) |> Enum.map(fn(arg) ->
      String.replace_suffix(arg, "-branches", "") |>
      String.replace_suffix("-all", "")
    end) |> Enum.map(fn(arg) ->
      case arg do
        "commit-count" -> "commit_count"
        "mix-env" -> "mix_env"
        "commit-count-branch" -> "commit_count_branch"
        "branch-unless-master" -> "branch_unless_master"
        command -> command
      end
    end)
  end

  @doc """
    Gets the version which should be set as fixed version (instead of incrementing) from the args
    and returns the args without that value.
  """
  @spec get_version_to_set_from_args(args::OptionParser.argv, remaining_args::OptionParser.argv) :: {version_to_set::String.t|nil, args_without_version::OptionParser.argv}
  def get_version_to_set_from_args(_args = [], remaining_args), do: {_version = nil, Enum.reverse(remaining_args)}
  def get_version_to_set_from_args(_args = ["set", version | remaining], remaining_args), do: {version, Enum.reverse(remaining_args) ++ ["set"|remaining]}
  def get_version_to_set_from_args(_args = [other | remaining], remaining_args), do: get_version_to_set_from_args(remaining, [other|remaining_args])

  @doc """
      Sorts the args in that way, that all args incrementing or setting the version come first
      and all args appending metadata come last by not changing their particular order.
  """
  @spec sort_args_append_metadata_last(args::OptionParser.argv, increment_version_args::OptionParser.argv, append_metadata_args::OptionParser.argv) :: args::OptionParser.argv
  def sort_args_append_metadata_last(_args = [], increment_version_args, append_metadata_args), do: Enum.reverse(increment_version_args) ++ Enum.reverse(append_metadata_args)
  def sort_args_append_metadata_last(_args = [arg|rest], increment_version_args, append_metadata_args) when arg in ["major", "minor", "patch", "set"] do
     sort_args_append_metadata_last(rest, [arg|increment_version_args], append_metadata_args)
  end
  def sort_args_append_metadata_last(_args = [arg|rest], increment_version_args, append_metadata_args) do
     sort_args_append_metadata_last(rest, increment_version_args, [arg|append_metadata_args])
  end

  def modify_version_major({version, has_metadata}), do: {update_version(version, :major), has_metadata}
  def modify_version_minor({version, has_metadata}), do: {update_version(version, :minor), has_metadata}
  def modify_version_patch({version, has_metadata}), do: {update_version(version, :patch), has_metadata}
  def modify_version_mix_env({version, has_metadata}),             do: {add_metadata(version, Atom.to_string(Mix.env),     has_metadata),        _has_metadata = true}
  def modify_version_commit_count({version, has_metadata}),        do: {add_metadata(version, __MODULE__.get_commit_count, has_metadata),        _has_metadata = true}
  def modify_version_commit_count_branch({version, has_metadata}), do: {add_metadata(version, __MODULE__.get_commit_count_branch, has_metadata), _has_metadata = true}
  def modify_version_revision({version, has_metadata}),            do: {add_metadata(version, __MODULE__.get_git_revision, has_metadata),        _has_metadata = true}
  def modify_version_date({version, has_metadata}),                do: {add_metadata(version, __MODULE__.get_date, has_metadata),                _has_metadata = true}
  def modify_version_branch({version, has_metadata}),              do: {add_metadata(version, __MODULE__.get_branch, has_metadata),              _has_metadata = true}
  def modify_version_branch_unless_master({version, has_metadata}) do
    case __MODULE__.get_branch do
      "master"     -> {version, has_metadata}
      other_branch -> {add_metadata(version, other_branch, has_metadata), _has_metadata = true}
    end
  end


  def modify_version_set({_version, has_metadata}, version_to_set), do: {version_to_set, has_metadata}


  defp add_metadata(version, metadata, _had_metadata = false), do: version <> "+" <> metadata
  defp add_metadata(version, metadata, _had_metadata = true),  do: version <> "-" <> metadata

  @doc """
    Modifies the current release version by applying the `modification_fun`s which
    were collected while parsing the args. If there was an error parsing the arguments
    passed to this task, this function prints the error and exists the erlang vm, meaning
    aborting the mix task. If `:show` is returned from parsing the arguments, this function
    just prints the current release version.
  """
  @spec modify_version({:modify, [modification_fun]} | {:error, message::String.t} | :show, version::String.t) :: :ok | :error | {:modified, new_version::String.t}
  def modify_version(:show, version) do
    IO.puts version
  end
  def modify_version({:error, message}, _version) do
    IO.puts :stderr, IO.ANSI.red <> "Error: " <> message <> IO.ANSI.reset
    :error
  end
  def modify_version({:modify, modification_functions}, version) do
    {version, _} = Enum.reduce modification_functions, {version, false},
      fn(modification_function, acc) when is_atom(modification_function) -> apply(__MODULE__, modification_function, [acc])
        (modification_function, acc) when is_function(modification_function, 1) -> apply(modification_function, [acc])
    end
    {:modified, version}
  end


  @doc """
    Gets the current revision of the git repository edeliver is used as deploy tool for.
    The sha1 hash containing 7 hexadecimal characters is returned.
  """
  @spec get_git_revision() :: String.t
  def get_git_revision() do
    System.cmd( "git", ["rev-parse", "--short", "HEAD"]) |> elem(0) |> String.rstrip
  end

  @doc "Gets the current number of commits across all branches"
  @spec get_commit_count() :: String.t
  def get_commit_count() do
    System.cmd( "git", ["rev-list", "--all", "--count"]) |> elem(0) |> String.rstrip
  end

  @doc "Gets the current number of commits in the current branch"
  @spec get_commit_count_branch() :: String.t
  def get_commit_count_branch() do
    System.cmd( "git", ["rev-list", "--count", "HEAD"]) |> elem(0) |> String.rstrip
  end

  @doc """
    Gets the current branch that will be built. Since the git repository on the build
    host is usually in a detatched state because a specific revision is checked out
    when building (see `git_reset_remote()` in `libexec/common`), this won't work:

    `git rev-parse --abbrev-ref HEAD`

    Instead

    `git branch --contains <revision>` could be used. But the commit/revision can still
    be in several branches, e.g. if one branch containing that commit was built before
    and that branch is later merged and built again. Then the old branch exists still
    on the build host and the commit exists in both branches. So whenever possible we
    will pass the branch which is built as `BRANCH` env, but as fallback we try to
    autodetect the branch which contains the current commit that is built.
  """
  @spec get_branch() :: String.t
  def get_branch() do
    case System.get_env("BRANCH") do
      branch = <<_,_::binary>> -> valid_semver_metadata(branch)
      _ -> # try to detect the branch, but commit might be in several branches
        System.cmd( "git", ["branch", "--contains", get_revision()]) |> elem(0)
        |> String.split("\n", trim: true)
        |> Enum.filter(&(!String.contains?(&1, "detached") && !String.contains?(&1, "head") && !String.contains?(&1, "HEAD")))
        |> Enum.map(&(String.strip(&1))) |> List.first() |> valid_semver_metadata()
    end
  end

  # Returns the current revision which is checked out and will be built.
  @spec get_revision() :: String.t
  defp get_revision() do
    System.cmd( "git", ["rev-parse", "HEAD"]) |> elem(0) |> String.rstrip
  end

  def valid_semver_metadata(nil), do: ""
  def valid_semver_metadata(string) do
    IO.chardata_to_string(for <<c <- string>>, (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) or (c >= ?0 and c <= ?9) or c == ?-, do: c)
  end

  @doc "Gets the current date in the form yyyymmdd"
  @spec get_date :: String.t
  def get_date() do
    {{year, month, day}, _time} = :calendar.local_time
    :io_lib.format('~4.10.0b~2.10.0b~2.10.0b', [year, month, day]) |> IO.iodata_to_binary
  end
end