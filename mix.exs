defmodule Edeliver.Mixfile do
  use Mix.Project

  def project do
    [
      app: :edeliver,
      version: "1.1.6",
      description:  "Build and Deploy Elixir Applications and perform Hot-Code Upgrades and Schema Migrations",
      package: [
        licenses: ["MIT"],
        files:  [
          "bin",
          "CHANGELOG.md",
          "lib",
          "libexec",
          "mix.exs",
          "src",
          "strategies",
          "README.md",
        ],
        links: %{"GitHub" => "https://github.com/boldpoker/edeliver"},
      ],
      deps: deps,
    ]
  end

  defp deps, do: [
    {:exrm, ">= 0.16.0"},
  ]

end
