defmodule Fastagi.MixProject do
  use Mix.Project

  def project do
    [
      app: :fastagi,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],

      # Docs
      name: "Fastagi",
      source_url: "https://github.com/staskobzar/exfastagi",
      homepage_url: "https://github.com/staskobzar/exfastagi",
      docs: [
        main: "Fastagi",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description() do
    "Elixir FastAGI library to build FastAGI servers and process Asterisk calls."
  end

  defp package() do
    [
      licenses: ["GPL-3.0+"],
      links: %{"GitHub" => "https://github.com/staskobzar/exfastagi"}
    ]
  end
end
