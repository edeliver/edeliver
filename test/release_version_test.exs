# If these tests don't run because :cover is missing, install `erlang-tools`
defmodule Edeliver.Release.Version.Test do
  use ExUnit.Case
  alias Mix.Tasks.Release.Version, as: ReleaseVersion
  import ExUnit.CaptureIO
  import ReleaseVersion, only: :functions

  setup_all do
    :meck.new ReleaseVersion, [:passthrough]
    :meck.expect(ReleaseVersion, :get_git_revision, fn -> "82a5834" end)
    :meck.expect(ReleaseVersion, :get_commit_count, fn -> "12345" end)
    :meck.expect(ReleaseVersion, :get_commit_count_branch, fn ->   "4321" end)
    :meck.expect(ReleaseVersion, :get_branch, fn -> "feature-xyz" end)
    :meck.expect(ReleaseVersion, :get_date, fn -> "20160414" end)
    :meck.expect(ReleaseVersion, :get_time, fn -> "110160" end)
    :ok
  end

  setup do
    assert :ok = System.delete_env("AUTO_VERSION")
  end

  test "mocking get git revision" do
    assert "82a5834" = get_git_revision()
  end

  test "mocking get commit count" do
    assert "12345" = get_commit_count()
  end

  test "mocking get current branch" do
    assert "feature-xyz" = get_branch()
  end

  test "mocking get current date" do
    assert "20160414" = get_date()
  end

  test "mocking get current time" do
    assert "110160" = get_time()
  end

  test "printing current release version for show argument" do
    assert capture_io(fn ->
      assert :ok = modify_version_with_args "1.2.3", "show"
    end) == "1.2.3\n"
  end

  test "appending commit count" do
    assert {:modified, "1.0.0+12345"} = modify_version_with_args "1.0.0", "append-git-commit-count-all"
    assert {:modified, "1.0.0+12345"} = modify_version_with_args "1.0.0", "append-git-commit-count-all-branches"
    assert {:modified, "1.0.0+12345"} = modify_version_with_args "1.0.0", "git-commit-count-all-branches"
    assert {:modified, "1.0.0+12345"} = modify_version_with_args "1.0.0", "commit-count-all"
    assert {:modified, "1.0.0+12345"} = modify_version_with_args "1.0.0", "append-git-commit-count"
    assert {:modified, "1.0.0+12345"} = modify_version_with_args "1.0.0", "append-commit-count"
    assert {:modified, "1.1.0+12345"} = modify_version_with_args "1.1.0", "commit-count"
  end

  test "appending commit count for current branch" do
    assert {:modified, "1.0.0+4321"} = modify_version_with_args "1.0.0", "append-git-commit-count-branch"
    assert {:modified, "1.0.0+4321"} = modify_version_with_args "1.0.0", "git-commit-count-branch"
    assert {:modified, "1.0.0+4321"} = modify_version_with_args "1.0.0", "commit-count-branch"
  end

  test "appending git revision" do
    assert {:modified, "1.0.0+82a5834"} = modify_version_with_args "1.0.0", "append-git-revision"
    assert {:modified, "1.0.1+82a5834"} = modify_version_with_args "1.0.1", "git-revision"
    assert {:modified, "1.2.3+82a5834"} = modify_version_with_args "1.2.3", "revision"
  end

  test "appending git branch" do
    assert {:modified, "1.0.0+feature-xyz"} = modify_version_with_args "1.0.0", "append-git-branch"
    assert {:modified, "1.0.1+feature-xyz"} = modify_version_with_args "1.0.1", "git-branch"
    assert {:modified, "1.2.3+feature-xyz"} = modify_version_with_args "1.2.3", "branch"
  end

  test "append git branch only unless master" do
    assert <<_,_::binary>> = mocked_branch = get_branch()
    assert mocked_branch != "master"
    try do
      assert {:modified, "1.0.0+feature-xyz"} = modify_version_with_args "1.0.0", "append-git-branch-unless-master"
      assert {:modified, "1.0.1+feature-xyz"} = modify_version_with_args "1.0.1", "git-branch-unless-master"
      assert {:modified, "1.2.3+feature-xyz"} = modify_version_with_args "1.2.3", "branch-unless-master"
      assert {:modified, "1.2.3+82a5834-feature-xyz"} = modify_version_with_args "1.2.3", "git-revision+branch-unless-master"
      assert {:modified, "1.2.3+feature-xyz-82a5834"} = modify_version_with_args "1.2.3", "branch-unless-master+git-revision"
      :meck.expect(ReleaseVersion, :get_branch, fn -> "master" end)
      assert {:modified, "1.0.0"} = modify_version_with_args "1.0.0", "append-git-branch-unless-master"
      assert {:modified, "1.0.1"} = modify_version_with_args "1.0.1", "git-branch-unless-master"
      assert {:modified, "1.2.3"} = modify_version_with_args "1.2.3", "branch-unless-master"
      assert {:modified, "1.2.3+82a5834"} = modify_version_with_args "1.2.3", "git-revision+branch-unless-master"
      assert {:modified, "1.2.3+82a5834"} = modify_version_with_args "1.2.3", "branch-unless-master+git-revision"
    after
      :meck.expect(ReleaseVersion, :get_branch, fn -> mocked_branch end)
      assert mocked_branch == get_branch()
    end
  end

  test "appending date" do
    assert {:modified, "1.0.0+20160414"} = modify_version_with_args "1.0.0", "append-build-date"
    assert {:modified, "1.0.1+20160414"} = modify_version_with_args "1.0.1", "build-date"
    assert {:modified, "1.2.3+20160414"} = modify_version_with_args "1.2.3", "date"
  end

  test "appending time" do
    assert {:modified, "1.0.0+110160"} = modify_version_with_args "1.0.0", "append-build-time"
    assert {:modified, "1.0.1+110160"} = modify_version_with_args "1.0.1", "build-time"
    assert {:modified, "1.2.3+110160"} = modify_version_with_args "1.2.3", "time"
  end

  test "appending commit count and git revision" do
    assert {:modified, "1.0.0+12345-82a5834"} = modify_version_with_args "1.0.0", "append-commit-count append-git-revision"
    assert {:modified, "1.2.0+12345-82a5834"} = modify_version_with_args "1.2.0", "commit-count+git-revision"
    assert {:modified, "1.2.3+82a5834-12345"} = modify_version_with_args "1.2.3", "append-git-revision append-commit-count"
    assert {:modified, "1.0.3+82a5834-12345"} = modify_version_with_args "1.0.3", "git-revision+commit-count"
  end

  test "appending commit count and git branch" do
    assert {:modified, "1.0.0+12345-feature-xyz"} = modify_version_with_args "1.0.0", "append-commit-count append-git-branch"
    assert {:modified, "1.2.0+12345-feature-xyz"} = modify_version_with_args "1.2.0", "commit-count+git-branch"
    assert {:modified, "1.2.3+feature-xyz-12345"} = modify_version_with_args "1.2.3", "append-git-branch append-commit-count"
    assert {:modified, "1.0.3+feature-xyz-12345"} = modify_version_with_args "1.0.3", "git-branch+commit-count"
  end

  test "increasing patch version" do
    assert {:modified, "1.0.1"} = modify_version_with_args "1.0.0", "increment patch"
    assert {:modified, "1.0.1"} = modify_version_with_args "1.0.0", "increment patch version"
    assert {:modified, "1.0.1"} = modify_version_with_args "1.0.0", "patch"
    assert {:modified, "1.2.4"} = modify_version_with_args "1.2.3", "increment patch"
    assert {:modified, "1.2.4"} = modify_version_with_args "1.2.3", "patch"
    assert {:modified, "1.2.1"} = modify_version_with_args "1.2", "patch"
    assert {:modified, "1.0.1"} = modify_version_with_args "1", "increment patch"
  end

  test "increasing minor version" do
    assert {:modified, "1.1.0"} = modify_version_with_args "1.0.0", "increment minor"
    assert {:modified, "1.1.0"} = modify_version_with_args "1.0.0", "increment minor version"
    assert {:modified, "1.1.0"} = modify_version_with_args "1.0.0", "minor"
    assert {:modified, "2.2.0"} = modify_version_with_args "2.1.3", "increment minor"
    assert {:modified, "1.3.0"} = modify_version_with_args "1.2.0", "minor"
    assert {:modified, "1.3.0"} = modify_version_with_args "1.2", "minor"
    assert {:modified, "2.1.0"} = modify_version_with_args "2", "increment minor"
  end

  test "increasing major version" do
    assert {:modified, "2.0.0"} = modify_version_with_args "1.0.0", "increment major"
    assert {:modified, "2.0.0"} = modify_version_with_args "1.0.0", "major"
    assert {:modified, "3.0.0"} = modify_version_with_args "2.1.3", "increment major"
    assert {:modified, "3.0.0"} = modify_version_with_args "2.1.3", "increment major version"
    assert {:modified, "2.0.0"} = modify_version_with_args "1.2.0", "major"
    assert {:modified, "2.0.0"} = modify_version_with_args "1.2", "major"
    assert {:modified, "5.0.0"} = modify_version_with_args "4", "increment major"
  end

  test "get version to set from args" do
    assert {_version_to_set = nil, ["increment", "major"]} = get_version_to_set_from_args("increment major" |> to_argv(), [])
    assert {_version_to_set = "2.0.0-beta", ["set"]} = get_version_to_set_from_args("set 2.0.0-beta" |> to_argv(), [])
    assert {_version_to_set = "2.1.0-beta.1", ["set", "append-commit-count"]} = get_version_to_set_from_args("set 2.1.0-beta.1 append-commit-count" |> to_argv(), [])
  end

  test "setting version " do
    assert {:modified, "1.2.3-beta.4"} = modify_version_with_args "1.0.0", "set version 1.2.3-beta.4"
    assert {:modified, "2.0.0-beta+12345"} = modify_version_with_args "1.0.0", "set version 2.0.0-beta append-commit-count"
    assert {:modified, "2.0.0-beta+12345-82a5834"} = modify_version_with_args "1.0.0", "set version 2.0.0-beta append-commit-count append-git-revision"
  end

  test "increasing version and appending metadata" do
    assert {:modified, "2.0.0+82a5834"} = modify_version_with_args "1.0.0", "increment major version append-git-revision"
    assert {:modified, "2.0.0+82a5834"} = modify_version_with_args "1.0.0", "major+git-revision"
    assert {:modified, "2.2.0+82a5834-12345-feature-xyz"} = modify_version_with_args "2.1.3", "increment minor append-git-revision append-commit-count append-branch"
    assert {:modified, "1.2.1+12345-82a5834-feature-xyz"} = modify_version_with_args "1.2", "patch commit-count revision branch"
  end

  test "appending metadata and increasing version" do
    assert {:modified, "2.0.0+82a5834"} = modify_version_with_args "1.0.0", "append-git-revision increment major version "
    assert {:modified, "2.0.0+82a5834"} = modify_version_with_args "1.0.0", "git-revision+major"
    assert {:modified, "2.2.0+82a5834-12345-feature-xyz"} = modify_version_with_args "2.1.3", "append-git-revision increment minor append-commit-count append-branch"
    assert {:modified, "1.2.1+12345-82a5834-feature-xyz"} = modify_version_with_args "1.2", "commit-count revision patch branch"
  end

  test "ignore leading or tailing concatenation character (+)" do
    assert {:modified, "2.0.0+82a5834"} = modify_version_with_args "1.0.0", "git-revision+major+"
    assert {:modified, "2.0.0+82a5834"} = modify_version_with_args "1.0.0", "+git-revision+major"
  end

  test "use AUTO_VERSION env as default" do
    assert :ok = System.put_env("AUTO_VERSION", "append-commit-count append-git-branch")
    assert {:modified, "1.0.0+12345-feature-xyz"} = modify_version_with_args "1.0.0", ""

    assert :ok = System.put_env("AUTO_VERSION", "append-git-branch append-commit-count")
    assert {:modified, "1.2.3+feature-xyz-12345"} = modify_version_with_args "1.2.3", ""
  end

  test "arguments should override AUTO_VERSION env" do
    assert :ok = System.put_env("AUTO_VERSION", "append-commit-count append-git-branch")
    assert {:modified, "1.0.0+82a5834"} = modify_version_with_args "1.0.0", "append-git-revision"

    assert :ok = System.put_env("AUTO_VERSION", "append-git-branch append-commit-count")
    assert {:modified, "1.2.1+12345-82a5834-feature-xyz"} = modify_version_with_args "1.2", "patch commit-count revision branch"
  end

  test "append version metadata if AUTO_VERSION env is set and no arguments are passed" do
    assert :ok = System.put_env("AUTO_VERSION", "append-git-revision")
    assert {:modified, "1.0.0+82a5834"} = modify_version_with_args "1.0.0", ""
  end

  test "AUTO_VERSION should be used in conjunction with increment major|minor|patch or set version" do
    assert :ok = System.put_env("AUTO_VERSION", "append-git-revision")
    assert {:modified, "2.0.0+82a5834"} = modify_version_with_args "1.0.0", "increment major"
    assert {:modified, "1.1.0+82a5834"} = modify_version_with_args "1.0.0", "increment minor"
    assert {:modified, "1.0.1+82a5834"} = modify_version_with_args "1.0.0", "increment patch"
    assert {:modified, "2.0.0-beta+82a5834"} = modify_version_with_args "1.0.0", "set 2.0.0-beta"
  end

  test "should fail for 'count' argument without leading 'commit-'" do
    assert <<_,_,_,_,_>> <> "Error: Unknown option 'count'" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", "count"
    end)
  end

  test "should fail for illegal major, minor or patch combinations" do
    assert <<_,_,_,_,_>> <> "Error: Illegal combination of options" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", "major minor"
    end)
    assert <<_,_,_,_,_>> <> "Error: Illegal combination of options" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", "major set 2.0.0-beta"
    end)
  end

  test "should fail for unknown arguments" do
    assert <<_,_,_,_,_>> <> "Error: Unknown options" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", "foo bar"
    end)
  end

  test "should fail if version to set is missing" do
    assert <<_,_,_,_,_>> <> "Error: No version to set for 'release.version' task. Please add the version as argument" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", "set"
    end)
    assert <<_,_,_,_,_>> <> "Error: No version to set for 'release.version' task. Please add the version as argument" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", "set append-commit-count"
    end)
  end

  test "should fail if increasing or setting version is used in AUTO_VERSION env" do
    assert :ok = System.put_env("AUTO_VERSION", "increment minor")
    assert <<_,_,_,_,_>> <> "Error: Increasing major|minor|path or setting version is not allowed" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", ""
    end)
    assert :ok = System.put_env("AUTO_VERSION", "set 2.0.0-beta")
    assert <<_,_,_,_,_>> <> "Error: Increasing major|minor|path or setting version is not allowed" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", ""
    end)
  end

  test "should fail if no args are set and no AUTO_VERSION env is set" do
    assert <<_,_,_,_,_>> <> "Error: No arguments passed to 'release.version' task and no AUTO_VERSION env is set" <> _ = capture_io(:stderr, fn ->
      assert :error = modify_version_with_args "1.0.0", ""
    end)
  end

  test "use valid semver for branch metadata" do
    assert "foo-bar-123" = valid_semver_metadata("foo-bar-123")
    assert "foo-barbaz" = valid_semver_metadata("foo-bar.baz")
    assert "foo-barz" = valid_semver_metadata("foo-barüz")
  end

  test "ensure Mix.ProjectStack is available" do
    assert :ok == GenServer.call(Mix.ProjectStack, {:update_stack, fn [%{} | _] = stack -> {:ok, stack} end})
  end

  ### test helpers ####

  defp modify_version_with_args(version, args) do
    args |> to_argv() |> parse_args() |> modify_version(version)
  end

  defp to_argv(string), do: String.split(string)

end
