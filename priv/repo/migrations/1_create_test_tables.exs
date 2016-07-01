defmodule Ectoo.Repo.Migrations.CreateTestTables do
  use Ecto.Migration

  def change do
    create table(:test_model) do
      add :title, :string
      add :description, :string
    end


    create table(:translations) do
      add :translatable_id, :integer
      add :translatable_type, :string
      add :locale, :string
      add :field, :string
      add :content, :text

      timestamps
    end
    create index :translations, [:translatable_id, :translatable_type]
    create index :translations, [:translatable_id, :translatable_type, :locale]
    create unique_index(:translations, [:translatable_id, :translatable_type, :locale, :field])
  end
end
