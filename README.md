# EctoTranslate
![](https://img.shields.io/hexpm/v/ecto_translate.svg) ![](https://img.shields.io/hexpm/dt/ecto_translate.svg) ![](https://img.shields.io/hexpm/dw/ecto_translate.svg) ![](https://img.shields.io/coveralls/smeevil/ecto_translate.svg) ![](https://img.shields.io/github/issues/smeevil/ecto_translate.svg) ![](https://img.shields.io/github/issues-pr/smeevil/ecto_translate.svg) ![](https://semaphoreci.com/api/v1/smeevil/ecto_translate/branches/master/shields_badge.svg)

EctoTranslate is a library that helps with translating Ecto data. EctoTranslate can help you with returning translated values of your Ecto data attributes. For this it uses a singe table called "translations" which will contain polymorphic entries for all of your Ecto data stucts.

You might also be interested in [set_locale](https://github.com/smeevil/set_locale) which will enable urls like ```http://www.example.com/nl-nl/foo/bar``` and set the correct locale.

## examples

Given an ecto module like :
```elixir
defmodule MyApp.Post do
  ...
  use EctoTranslate, [:title, :body]
  ...
  schema "posts" do
    field :title, :string
    field :body, :string
  end
  ...
end
```

You can set translations using :
```elixir
record = MyApp.Repo.get(MyApp.Post, 1)
EctoTranslate.set(record, locale: :nl, title: "Een nederlandse titel",  description: "Een nederlandse beschrijving"]
```

Then you can ask for a translated fields explicitly using :

```elixir
iex> MyApp.Post.translated_title(post, :nl)
"Een nederlandse titel"
```

Or you can update the model by replacing the fields with their translations using :

```elixir
iex> translated_post = MyApp.Post.translate!(post, :nl)
iex> translated_post.title
"Een nederlandse titel"

iex> translated_post.description
"Een nederlandse beschrijving"
```

You can also pass in a collection to translate in batch preventing n+1 queries
```elixir
iex> posts = MyApp.Post |> MyApp.Repo.all
iex> translated_posts = MyApp.Post.translate!(posts, :nl)
```

If a translation is not found, it will fall back to the original database value.
If you ommit the locale in the function calls, the current gettext locale will be used.

```elixir
iex> Gettext.set_locale(MyApp.Gettext, :nl)
iex> translated_post = MyApp.Post.translate!(post)
iex> translated_post.title
```
### Docs
Docs can be found [here](https://smeevil.github.io/ecto_translate/EctoTranslate.html)

## Installation

1. Add `ecto_translate` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ecto_translate, "~> 0.1.0"}]
    end
    ```

1. Ensure `ecto_translate` is started before your application:

    ```elixir
    def application do
      [applications: [:ecto_translate]]
    end
    ```

1. Create a migration for the translation table :

    ```shell
    mix ecto.gen.migration create_translations
    vi priv/repo/migrations/<date>_create_translations.exs
    ```

    ```elixir
    defmodule MyApp.Repo.Migrations.CreateTranslations do
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
    ```

1. Migrate
    ```shell
    mix ecto.migrate
    ```
1. Update your config.exs and add these settings

    ```elixir
    config :ecto_translate, repo: MyApp.Repo, gettext: MyApp.Gettext
    ```

1. Add the macro to your model that you want to translate
    ```elixir
    defmodule MyApp.Post do
      ...
      import Ecto.Query
      use EctoTranslate, [:title, :body]
      ...
      schema "posts" do
        field :title, :string
        field :body, :string
      end
      ...
    end
    ```
    **Important:** Don't forget to import `Ecto.Query` before `use EctoTranslate`

1. Set translations for your data

    ```elixir
    record = MyApp.Repo.get(MyApp.Post, 1)
    EctoTranslate.set(record, locale: :nl, title: "Een nederlandse titel",  description: "Een nederlandse beschrijving"]
    ```

1. Use the translations


    ```elixir
    iex> translated_post = MyApp.Post.translate!(post, :nl)
    iex> translated_post.title
    "Een nederlandse titel"
    ```
    or

    ```elixir
    iex> MyApp.Post.translated_title(post, :nl)
    "Een nederlandse titel"
    ```
