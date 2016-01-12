defmodule Mix.Tasks.Release.Version do
  use Mix.Task

  @shortdoc "Displays or modifies the release version"

  @moduledoc """
  Displays the release version or modifies it before building the release.
  This task can be used in conjunction with the `release` task to modify
  the version for the release / upgrade.

  # Usage:

    * mix release.version [show]
    * mix release.version set <new-version> [Option]
    * mix release.version increase [patch|minor|major] [version] [Option]
    * mix release.version append-git-revision [Option]

  ## Actions
    * `show` Displays the current release version.
    * `append-git-revision` Append sha1 git revision of current HEAD
    * `increase` Increases the release version
      - `patch` Increases the patch version (default). The last part of a tripartite version.
      - `minor` Increases the minor version. The middle part of a tripartite version.
      - `major` Increases the major version. The first part of a tripartite version.

  ## Options
    * `-V`, `--verbose` Verbose output
    * `-Q`, `--quiet` Print errors only while modifying version


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
end