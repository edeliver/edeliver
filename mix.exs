defmodule Edeliver.Mixfile do
  use Mix.Project

  def project do
    [
      app: :edeliver,
      version: "1.8.0",
      elixir: ">= 1.10.0",
      description:  "Build and Deploy Elixir Applications and perform Hot-Code Upgrades and Schema Migrations",
      elixirc_paths: elixirc_paths(),
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
        maintainers: [],
        links: %{"GitHub" => "https://github.com/boldpoker/edeliver"},
      ],
      deps: deps(),
      docs: docs(),
    ]
  end

  def application, do:
    [applications: [],
     mod: {Edeliver, []},
     registered: [Edeliver.Supervisor, Edeliver],
     env: []
   ]

  defp deps do
    [
      {:distillery, "~> 2.1.0", optional: true, warn_missing: false},
      {:meck, "~> 0.8.13", only: :test},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
    ]
  end

  defp docs, do: [
    logo: "docs/logo.png",
    extras: [
      "README.md": [title: "Usage"],
      "docs/auto-versioning.md": [title: "Auto-Versioning"],
      "docs/relup-patching.md": [title: "Relup-Patching"],
    ]
  ]

  defp elixirc_paths() do
    [
      Path.join("lib", "distillery"),
      Path.join("lib", "edeliver"),
      Path.join("lib", "mix"),
      Path.join("lib", "edeliver.ex")
    ]
  end
end
