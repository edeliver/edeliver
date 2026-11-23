defmodule Eco.Mixfile do
  use Mix.Project

  def project do
    [app: :eco,
     version: "0.1.0",
     elixir: "~> 1.20",
     start_permanent: Mix.env() == :prod,
     erlc_paths: ["apps/eco/src"],
     deps: deps()]
  end

  def application do
    [extra_applications: [:sasl, :logger],
     mod: {:eco_app, []}]
  end

  defp deps do
    [{:ranch, "~> 1.8"},
     # the edeliver version under test, copied into the project by the test script
     {:edeliver, path: "vendor/edeliver"}]
  end
end
