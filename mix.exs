defmodule EctoTranslate.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ecto_translate,
      description:
        "EctoTranslate is a library that helps with translating Ecto data. EctoTranslate can help you with returning translated values of your Ecto data attributes. For this it uses a singe table called 'translations' which will contain polymorphic entries for all of your Ecto data stucts.",
      version: "0.2.3",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [applications: applications(Mix.env())]
  end

  defp applications(:test), do: [:logger, :postgrex]
  defp applications(_), do: [:logger]

  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:ecto, "~> 3.0"},
      {:gettext, "~>0.16"},
      {:credo, ">= 0.0.0", only: [:dev, :test]},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:excoveralls, ">= 0.0.0 ", only: :test},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "test.setup": ["ecto.create", "ecto.migrate"],
      "test.reset": ["ecto.drop", "test.setup"]
    ]
  end

  defp package do
    [
      maintainers: ["Gerard de Brieder"],
      licenses: ["WTFPL"],
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      links: %{
        "GitHub" => "https://github.com/smeevil/ecto_translate",
        "Docs" => "https://smeevil.github.io/ecto_translate/EctoTranslate.html"
      }
    ]
  end
end
