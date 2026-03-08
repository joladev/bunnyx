defmodule Bunnyx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/joladev/bunnyx"

  def project do
    [
      app: :bunnyx,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      warnings_as_errors: true,
      deps: deps(),
      name: "Bunnyx",
      description: "Elixir client for the bunny.net CDN API.",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:mimic, "~> 2.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        API: [Bunnyx.PullZone, Bunnyx.DnsZone, Bunnyx.DnsRecord, Bunnyx.Purge, Bunnyx.Storage],
        Core: [Bunnyx, Bunnyx.HTTP, Bunnyx.Error, Bunnyx.Storage.Object]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
