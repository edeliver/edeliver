defmodule Edeliver.Mixfile do
  use Mix.Project

  @source_url "https://github.com/boldpoker/edeliver"
  @version "1.9.2"

  def project do
    [
      app: :edeliver,
      version: @version,
      elixir: ">= 1.10.0",
      elixirc_paths: elixirc_paths(),
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      applications: [],
      mod: {Edeliver, []},
      registered: [Edeliver.Supervisor, Edeliver],
      env: []
    ]
  end

  defp deps do
    [
      {:distillery, git: "https://github.com/altenwald/distillery.git", commit: "7c749b0"},
      {:artificery, github: "storestartup/artificery", override: true},
      {:meck, "~> 0.8.13", only: :test},
      {:ex_doc, ">= 0.28.4", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "README.md": [title: "Usage"],
        "guides/docker.md": [title: "Docker Support"],
        "guides/auto-versioning.md": [title: "Auto-Versioning"],
        "guides/relup-patching.md": [title: "Relup-Patching"]
      ],
      main: "readme",
      assets: "assets",
      logo: "assets/logo.png",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description:
        "Build and Deploy Elixir Applications and perform " <>
          "Hot-Code Upgrades and Schema Migrations",
      licenses: ["MIT"],
      files: [
        "bin",
        "CHANGELOG.md",
        "docker",
        "lib",
        "libexec",
        "mix.exs",
        "src",
        "strategies",
        "README.md"
      ],
      maintainers: [],
      links: %{
        "Changelog" => "https://hexdocs.pm/edeliver/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp elixirc_paths do
    [
      Path.join("lib", "distillery"),
      Path.join("lib", "edeliver"),
      Path.join("lib", "mix"),
      Path.join("lib", "edeliver.ex")
    ]
  end
end
