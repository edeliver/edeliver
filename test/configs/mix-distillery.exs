defmodule EcoDistillery.Mixfile do
  use Mix.Project

  def project do
    [app: :eco,
     version: "0.1.0",
     elixir: "~> 1.11",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: [:app, :erlang],
     erlc_paths: ["apps/eco/src"],
     erlc_options: [:debug_info, {:parse_transform, :lager_transform}],
     deps: deps()]
  end

  def application do
    [applications: [:sasl, :edeliver, :lager, :ranch],
     mod: {:eco_app, []}]
  end

  defp deps do
    [{:lager, "== 3.6.7"},
     {:ranch, "~> 1.6.2"},
     {:distillery, "~> 2.0"},
     {:edeliver, "~> 1.9.0"}]
  end
end