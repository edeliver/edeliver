defmodule Edeliver.Relup.Config do
  @moduledoc """
    This type represents the current config of the release manager.

    When using exrm it is a `ReleaseManager.Config.t` struct,
    when using distillery it is a `Mix.Releases.Config.t` struct.
  """

  @type t :: term
end