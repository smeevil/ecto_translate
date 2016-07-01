defmodule EctoTranslate.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ecto_translate,
      version: "0.1.0",
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      aliases: aliases,
      package: package
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: [:logger, :postgrex]
  defp applications(_), do: [:logger]
  defp deps do
    [
      {:ecto, "~>2.0.0"},
      {:gettext, ">0.0.0"},
      {:postgrex, "> 0.0.0", only: [:dev, :test]},
      {:credo, "> 0.0.0", only: [:dev, :test]},
      {:earmark , "~> 0.2.1"  , only: :dev},
      {:ex_doc  , "~> 0.12.0" , only: :dev}
    ]
  end

  defp aliases do
    [
      "test.setup": ["ecto.create", "ecto.migrate"],
      "test.reset": ["ecto.drop", "test.setup"],
    ]
  end

  defp package do
    [
      maintainers: ["Gerard de Brieder"],
      licenses: ["WTFPL"],
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      links: %{
        "GitHub" => "https://github.com/smeevil/ecto_translate",
        "Docs"   => "https://smeevil.github.io/ecto_translate/EctoTranslate.html"
      }
    ]
  end

end
