
defmodule Edeliver.CommonFunctions.Test do
  use Edeliver.BashScript.Case, bash_script: Path.join([__DIR__, "..", "libexec", "erlang"])

  test "trimming strings" do
    assert "foo" = call "trim_string", " foo"
    assert "bar" = call "trim_string", "bar "
    assert "baz" = call "trim_string", " baz "
    assert "don't baz" = call "trim_string", " don't baz "
  end

  test "joining string" do
    assert "foo bar" = call "__join_string", " ", "foo", "bar"
    assert "foo bar" = call "__join_string", " ", " foo", "bar "
    assert "foo,bar" = call "__join_string", ",", "foo", "bar"
  end

  test "get args for release.version task" do
    assert "" = call "__get_auto_version_args"
    with_env INCREMENT_RELEASE_VERSION: "major" do
      assert "major" = call "__get_auto_version_args"
    end
    with_env SET_RELEASE_VERSION: "1.2.3-beta.1" do
      assert "1.2.3-beta.1" = call "__get_auto_version_args"
    end
    with_env AUTO_RELEASE_VERSION: "revision+branch" do
      assert "revision+branch" = call "__get_auto_version_args"
    end
    with_env INCREMENT_RELEASE_VERSION: "minor", AUTO_RELEASE_VERSION: "revision+branch" do
      assert "minor revision+branch" = call "__get_auto_version_args"
    end
    with_env SET_RELEASE_VERSION: "1.2.3-beta.1", AUTO_RELEASE_VERSION: "commit-count" do
      assert "1.2.3-beta.1 commit-count" = call "__get_auto_version_args"
    end
    with_env INCREMENT_RELEASE_VERSION: " patch ", AUTO_RELEASE_VERSION: " revision " do
      assert "patch revision" = call "__get_auto_version_args"
    end
  end


end