defmodule Edeliver.Mixfile do
  use Mix.Project

  def project do
    [
      app: :edeliver,
      version: "1.0.0",
      description:  "Build and Deploy Elixir Applications and perform Hot-Code Upgrades",
      package: [
        licenses: ["MIT"],
        files:  [
          "bin",
          "lib",
          "libexec",
          "src",
          "strategies",
          "README.md",
        ],
        links: %{"GitHub" => "https://github.com/boldpoker/edeliver"},
        deps: deps,
      ],
    ]
  end

  defp deps, do: [
    {:exrm, "~> 0.16.0"},
  ]

end