defmodule Mix.Tasks.Release.Version do
  use Mix.Task

  @shortdoc "Displays or modifies the release version"

  @moduledoc """
  Displays the release version or modifies it before building the release.
  This task can be used in conjunction with the `release` task to modify
  the version for the release / upgrade. The compiled files must be cleaned
  before and the release task must be executed after. Increasing version
  and appending metadata to the version can be combined, e.g:

  `mix do clean, release.version increase minor append-git-revision append-branch, release`

  To automatically append metadata, you can set the `$AUTO_VERSION` environment variable.

  # Usage:

    * mix release.version [show]
    * mix do clean, release.version set <new-version> [Option], release
    * mix do clean, release.version increase [patch|minor|major] [version] [Option], release
    * mix do clean, release.version [append-][git-]revision|commit-count|branch [Option], release
    * mix do clean, release.version [append-][build-]date [Option], release

  ## Actions
    * `show` Displays the current release version.
    * `append-git-revision` Appends sha1 git revision of current HEAD
    * `append-git-commit-count` Appends the number of commits across all branches
    * `append-git-branch` Appends the current branch that is built
    * `append-build-date` Appends the build date as YYYY.MM.DD
    * `increase` Increases the release version
      - `patch` Increases the patch version (default). The last part of a tripartite version.
      - `minor` Increases the minor version. The middle part of a tripartite version.
      - `major` Increases the major version. The first part of a tripartite version.

  ## Options
    * `-V`, `--verbose` Verbose output
    * `-Q`, `--quiet` Print only errors while modifying version


  ## Example

    `MIX_ENV=prod mix do release.version append-git-revision, release`
  """
  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    case args do
      ["show" | options] ->                print_version(options)
      ["set", new_version | options] ->    set_version(check_new_version(new_version), options)
      ["set"] ->                           check_new_version("--")
      ["increase" | options] ->            set_version(get_increase_option(options), options)
      ["append-git-revision" | options] -> set_version(:git, options)
      options ->                           print_version(options)
    end
  end

  @privdoc """
    Sets the release version to the new value or increases it
  """
  @spec set_version(version::String.t|:patch|:minor|:major|:git, options::[String.t]) :: new_version::String.t
  defp set_version(version, options) do
    {old_version, new_version} = Agent.get_and_update Mix.ProjectStack, fn(state) ->
      [root=%{config: config}|rest] = state.stack
      {old_version, new_version, config} = List.foldr config, {"","", []}, fn({key, value}, {old_version, new_version, config}) ->
        if key == :version do
          old_version = value
          new_version = update_version(old_version, version)
          value = new_version
        end
        {old_version, new_version, [{key, value}|config]}
      end
      stack = [%{root|config: config}|rest]
      {{old_version, new_version}, %{state| stack: stack}}
    end
    debug "Changed release version from #{old_version} to #{new_version}", options
  end

  defp print_version(options) do
    Mix.Shell.IO.info get_version
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
  defp update_version(old_version, :git) do
    git_revision = System.cmd( "git", ["rev-parse", "--short", "HEAD"]) |> elem(0) |> String.rstrip
    case String.split(old_version, "-") do
      [version|_] -> version <> "-" <> git_revision
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

  defp quiet?(options) do
    Enum.member?(options, "-Q") or Enum.member?(options, "--quiet")
  end

  defp verbose?(options) do
    Enum.member?(options, "-V") or Enum.member?(options, "--verbose")
  end

  defp check_new_version("--" <> _) do
    Mix.Shell.IO.error "Missing version to set."
    System.halt 1
  end
  defp check_new_version(version), do: version

  defp get_increase_option(options) do
    cond do
      Enum.member?(options, "major") -> :major
      Enum.member?(options, "minor") -> :minor
      true -> :patch
    end
  end

  @type modification_arg :: {modified_version::String.t, has_metadata::boolean}
  @type modification_fun :: ((modification_arg) -> modification_arg)

  @spec parse_args(OptionParser.argv) :: :show | {:error, message::String.t} | {:modify, [modification_fun]}
  def parse_args(args) do
    args = args |> List.foldr([], fn(arg, acc) ->
      if String.contains?(arg, "+") do
        String.split(arg, "+") ++ acc
      else
        [arg | acc]
      end
    end) |> Enum.filter(&(&1 != "increase" && &1 != "version"))
    args = args |> Enum.map(fn(arg) ->
      case arg do
        "append-" <> command -> command
        command -> command
      end
    end) |> Enum.map(fn(arg) ->
      case arg do
        "commit-count" -> "commit_count"
        "git-" <> command -> command
        "build-" <> command -> command
        command -> command
      end
    end)
    known_options = ["major", "minor", "patch", "commit_count", "revision", "date", "branch", "set"]
    unknown_options = args -- known_options
    illegal_combinations = Enum.filter args, &(Enum.member?(["major", "minor", "patch", "set"], &1))
    cond do
      args == ["show"] -> :show
      unknown_options == ["count"] -> {:error, "Unknown option 'count'.\nDid you mean 'commit-count'?"}
      Enum.count(unknown_options) > 0 -> {:error, "Unknown options: #{Enum.join(unknown_options, " ")}"}
      args == [] -> :show
      Enum.count(illegal_combinations) > 1 -> {:error, "Illegal combination of options: #{Enum.join(illegal_combinations, " ")} can't be used together."}
      true -> {:modify, Enum.map(args, &(String.to_atom("modify_version_" <> &1)))}
    end
  end

  def modify_version_major({version, has_metadata}), do: {update_version(version, :major), has_metadata}
  def modify_version_minor({version, has_metadata}), do: {update_version(version, :minor), has_metadata}
  def modify_version_patch({version, has_metadata}), do: {update_version(version, :patch), has_metadata}
  def modify_version_commit_count({version, has_metadata}), do: {add_metadata(version, __MODULE__.get_commit_count, has_metadata), _has_metadata = true}
  def modify_version_revision({version, has_metadata}), do:     {add_metadata(version, __MODULE__.get_git_revision, has_metadata), _has_metadata = true}
  def modify_version_date({version, has_metadata}), do:         {add_metadata(version, __MODULE__.get_date, has_metadata),         _has_metadata = true}
  def modify_version_branch({version, has_metadata}), do:       {add_metadata(version, __MODULE__.get_branch, has_metadata),       _has_metadata = true}


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
  def modify_version({:error, message}, version) do
    IO.puts :stderr, IO.ANSI.red <> "Error: " <> message <> IO.ANSI.reset
    :error
  end
  def modify_version({:modify, modification_functions}, version) do
    {version, _} = Enum.reduce modification_functions, {version, false}, &(apply(__MODULE__,&1, [&2]))
    {:modified, version}
  end


  @doc """
    Gets the current revision of the git repository edeliver is used as deploy tool for.
    The sha1 hash containing 7 hexadecimal characters is returned.
  """
  @spec get_git_revision() :: String.t
  def get_git_revision() do
    ""
  end

  @doc "Gets the current number of commits across all branches"
  @spec get_commit_count() :: String.t
  def get_commit_count() do
    "" # git rev-list --all --count
  end

  @doc "Gets the current branch that will be built"
  @spec get_branch() :: String.t
  def get_branch() do

  end


  @spec get_date :: String.t
  def get_date() do

  end
end