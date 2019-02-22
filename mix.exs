defmodule EctoTranslate.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ecto_translate,
      description:
        "EctoTranslate is a library that helps with translating Ecto data. EctoTranslate can help you with returning translated values of your Ecto data attributes. For this it uses a singe table called 'translations' which will contain polymorphic entries for all of your Ecto data stucts.",
      version: "1.0.0",
      elixir: "~> 1.7",
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
      test_coverage: [
        tool: ExCoveralls
      ],
      dialyzer: [
        plt_add_apps: [:mix, :ecto, :gettext, :eex, :ecto_sql],
        ignore_warnings: ".dialyzer_ignore",
        flags: [
          :unknown,
          :error_handling,
          :race_conditions
        ]
      ]

    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [applications: applications(Mix.env())]
  end

  defp applications(:test), do: [:logger, :ecto_sql, :postgrex]
  defp applications(_), do: [:logger]

  defp deps do
    [
      {:credo, ">= 0.0.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ecto, "~>3.0.7"},
      {:ecto_sql, ">=3.0.5"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:excoveralls, ">= 0.0.0 ", only: :test},
      {:gettext, "~>0.16.1"},
      {:postgrex, ">= 0.14.1", only: [:dev, :test]}
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
