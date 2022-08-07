defmodule Redeagle.MixProject do
  use Mix.Project

  @version "0.1.0"
  @scm_url "https://github.com/guiferreira/redeagle_new"
  @version_phoenix "1.6.11"
  def project do
    [
      app: :redeagle_new,
      version: @version,
      version_phoenix: @version_phoenix,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        name: "redeagle_new",
        maintainers: [
          "Gui Ferreira"
        ],
        licenses: ["MIT"],
        links: %{"GitHub" => @scm_url},
        files: ~w(lib templates mix.exs test README.md)
      ],
      preferred_cli_env: [docs: :docs],
      source_url: @scm_url,
      docs: docs(),
      homepage_url: @scm_url,
      description: """
      Redeagle framework project generator.

      Provides a `mix redeagle.new` task to bootstrap a new project: Phoenix + React + Docker.
      """
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
      {:phx_new, @version_phoenix},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_url_pattern: "#{@scm_url}",
      app: "redeagle_new",
      extras: ["README.md"]
    ]
  end
end
