defmodule UeberauthSAML.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/codesandbox/ueberauth_saml"

  def project do
    [
      app: :ueberauth_saml,
      version: @version,
      name: "Ueberauth SAML Strategy",
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      source_url: @url,
      homepage_url: @url,
      description: description(),
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.10"}
    ]
  end

  defp description do
    "An Ueberauth strategy for SAML-based identity providers"
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md": [title: "Overview"],
        "guides/getting-started.md": [title: "Getting Started"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        LICENSE: [title: "License"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["AJ Foster"],
      licenses: ["MIT"],
      links: %{GitHub: @url}
    ]
  end
end
