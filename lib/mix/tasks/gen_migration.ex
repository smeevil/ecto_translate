defmodule Mix.Tasks.EctoTranslate.Gen.Migration do
  @moduledoc """
  Generates a migration for translation table

  This task is able to take same arguments as `ecto.gen.migration` except name

  ## Exmaples

      mix ecto_translate.gen.migration
      mix ecto_translate.gen.migration -r Custom.Repo

  The generated migration filename will be prefixed with the current
  timestamp in UTC which is used for versioning and ordering.

  By default, the migration will be generated to the
    "priv/YOUR_REPO/migrations" directory of the current application
    but it can be configured to be any subdirectory of `priv` by
    specifying the `:priv` key under the repository configuration.

    This generator will automatically open the generated file if
    you have `ECTO_EDITOR` set in your environment variable.

    ## Command line options

      * `-r`, `--repo` - the repo to generate migration for
  """
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto

  @migration_name "ecto_translate_table"

  @shortdoc "Generates a new migration for the EctoTranslate translation table"

  def run(args) do
    no_umbrella!("ecto_translate.gen.migration")
    repos = parse_repo(args)

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      path = migrations_path(repo)
      file = Path.join(path, "#{timestamp()}_#{underscore(@migration_name)}.exs")
      create_directory path

      assigns = [mod: Module.concat([repo, Migrations, camelize(@migration_name)]),
                 change: change()]
      create_file file, migration_template(assigns)

      if open?(file) and Mix.shell.yes?("Do you want to run this migration?") do
        Mix.Task.run "ecto.migrate", [repo]
      end
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  defp change do
    """
        create table(:test_model) do
          add :title, :string
          add :description, :string
        end

        create table(:translations) do
          add :translatable_id, #{inspect(EctoTranslate.translatable_id_type())}
          add :translatable_type, :string
          add :locale, :string
          add :field, :string
          add :content, :text

          timestamps
        end

        create index :translations, [:translatable_id, :translatable_type]
        create index :translations, [:translatable_id, :translatable_type, :locale]
        create unique_index(:translations, [:translatable_id, :translatable_type, :locale, :field])
    """
  end

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration
    def change do
  <%= @change %>
    end
  end
  """
end
