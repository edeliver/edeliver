defmodule Edeliver.Mixfile do
  use Mix.Project

  def project do
    [
      app: :edeliver,
      version: "1.2.10",
      description:  "Build and Deploy Elixir Applications and perform Hot-Code Upgrades and Schema Migrations",
      elixirc_paths: elixirc_paths,
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
      docs: docs,
    ]
  end

  def application, do:
    [applications: [],
     mod: {Edeliver, []},
     registered: [Edeliver.Supervisor, Edeliver],
     env: []
   ]

  defp deps do
    if project_uses_distillery? do
      [
        {:distillery, ">= 0.8", warn_missing: false},
        {:exrm, ">= 0.16.0", optional: true, warn_missing: false},
      ]
    else
      [
        {:exrm, ">= 0.16.0", warn_missing: false},
        {:distillery, ">= 0.8", optional: true, warn_missing: false},
      ]
    end ++
    [
      {:meck, "~> 0.8.4", only: :test},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11.5", only: :dev},
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

  defp elixirc_paths do

    if project_uses_distillery? do
      [Path.join("lib", "distillery")]
    else
      [Path.join("lib", "exrm")]
    end ++ [
      Path.join("lib", "edeliver"),
      Path.join("lib", "mix"),
      Path.join("lib", "edeliver.ex"),
    ]
  end

  defp project_uses_distillery? do
    try do
      Mix.Project.get() |> Kernel.apply(:project, []) |> Keyword.get(:deps) |> List.keymember?(:distillery, 0)
      rescue error ->
        Mix.Shell.IO.error "Error when detecting whether distillery is used as release build tool: #{inspect error}"
        false
      catch signal, error ->
        Mix.Shell.IO.error "Failed to detect whether distillery is used as release build tool with signal: #{inspect signal} and error: #{inspect error}"
        false
    end

  end

end
