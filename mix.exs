defmodule Edeliver.Mixfile do
  use Mix.Project

  def project do
    [
      app: :edeliver,
      version: "1.4.2",
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
      {:distillery, ">= 0.8.0", optional: true, warn_missing: false},
      {:exrm, ">= 0.16.0", optional: true, warn_missing: false},
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

    if project_uses_distillery?() do
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
      deps = Mix.Dep.Loader
          |> Kernel.apply(:children, [])
          |> Enum.map(&(Map.get(&1, :app)))
      uses_distillery? = Enum.member?(deps, :distillery)
      uses_exrm? = Enum.member?(deps, :exrm)
      cond do
        uses_distillery? and uses_exrm? ->
          case System.get_env("USING_DISTILLERY") do
            "false" -> false
            "true"  -> true
            _ ->
              warning "Warning: Detected that both, :distillery and :exrm are used as dependency.\n"
                   <> "         edeliver will use :distillery as build tool unless you remove it \n"
                   <> "         as dependency or set the environment variable USING_DISTILLERY='false'."
              true
          end
        uses_distillery? -> true
        uses_exrm? -> false
        true ->
          case System.get_env("PUBLISHING_TO_HEX_PM") do
            "true" -> false
            _ ->
              Mix.Shell.IO.error "Failed to detect whether :distillery or :exrm is used as dependency.\n"
                              <> "If you used exrm before (default), please add it to your mix.exs\n"
                              <> "config file like this:\n\n"
                              <> "defp deps do\n"
                              <> "  [\n"
                              <> "   ...\n"
                              <> "   {:exrm, \">= 0.16.0\", warn_missing: false},\n"
                              <> "  ]\n"
                              <> "end\n\n"
                              <> "or upgrade to distillery as build tool. You find more information\n"
                              <> "about how to upgrade on the edeliver wiki page:\n\n"
                              <> "https://github.com/boldpoker/edeliver/wiki/Upgrade-from-exrm-to-distillery-as-build-tool\n\n"

              System.halt(1)
          end
      end
      rescue error ->
        Mix.Shell.IO.error "Error when detecting whether distillery or exrm is used as release build tool: #{inspect error}"
        System.halt(1)
      catch signal, error ->
        Mix.Shell.IO.error "Failed to detect whether distillery or exrm is used as release build tool with signal: #{inspect signal} and error: #{inspect error}"
        System.halt(1)
    end
  end

  defp warning(message) do
     IO.puts IO.ANSI.format [:yellow, :bright, message]
  end

end
