use Mix.Config

config :ecto_translate, EctoTranslate.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "ecto_translate_test",
  username: System.get_env("ECTO_TRANSLATE_DB_USER") || System.get_env("USER")

config :ecto_translate,
  ecto_repos: [EctoTranslate.Repo],
  repo: EctoTranslate.Repo,
  gettext: EctoTranslate.Gettext

config :logger, level: :info
