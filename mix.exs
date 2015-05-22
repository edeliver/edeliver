defmodule Edeliver.Mixfile do
  use Mix.Project

  def project do
    [
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
      ],
    ]
  end
end