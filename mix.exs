defmodule TowerOpentelemetry.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/tuist/tower_opentelemetry"

  def project do
    [
      app: :tower_opentelemetry,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "TowerOpentelemetry",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:tower, "~> 0.8"},
      {:opentelemetry_api, "~> 1.4"},
      {:opentelemetry, "~> 1.5", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:quokka, "~> 2.12", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Tower reporter that records exceptions as OpenTelemetry span events following the OpenTelemetry semantic conventions for exceptions."
  end

  defp package do
    [
      maintainers: ["Tuist GmbH"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Tower" => "https://github.com/mimiquate/tower"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end
end
