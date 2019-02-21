defmodule EctoTranslate do
  @moduledoc """
  EctoTranslate is a library that helps with translating Ecto data. EctoTranslate can help you with returning translated values of your Ecto data attributes. For this it uses a singe table called "translations" which will contain polymorphic entries for all of your Ecto data stucts.

  ## examples

  Given an ecto module like :

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

  You can set translations using :
  locale: :nl, title: "Een nederlandse titel",  description: "Een nederlandse beschrijving"]

  Then you can ask for a translated fields explicitly using :

      iex> MyApp.Post.translated_title(post, :nl)
      "Een nederlandse titel"

  Or you can update the model by replacing the fields with their translations using :

      iex> translated_post = MyApp.Post.translate!(post, :nl)
      iex> translated_post.title
      "Een nederlandse titel"
      iex> translated_post.description
      "Een nederlandse beschrijving"

  You can also pass in a collection to translate in batch preventing n+1 queries
      iex> posts = MyApp.Post |> MyApp.Repo.all
      iex> translated_posts = MyApp.Post.translate!(posts, :nl)

  If a translation is not found, it will fall back to the original database value.
  If you ommit the locale in the function calls, the current gettext locale will be used.

      iex> Gettext.set_locale(MyApp.Gettext, :nl)
      iex> translated_post = MyApp.Post.translate!(post)
      iex> translated_post.title
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @doc """
  EctoTranslate is meant to be `use`d by a module.

  `use` needs a list of attributes that you would like to make available for translation.

      defmodule MyApp.Post do
        use EctoTranslatable, [:title, :body]
      end

  When `use` is called, it will add the following functions to your module
    - translatable_fields/0
    - translate!/1
    - translate!/2
    - translated_attr/1 i.e. translated_title/1
    - translated_attr/2 i.e. translated_title/2

  For each of the functions the second parameter is an optional locale. if ommitted, it will use the current Gettext locale.
  """
  @spec __using__(fields :: List.t[Atom.t]) :: nil
  defmacro __using__(fields) do
    repo = Application.get_env(:ecto_translate, :repo)

    translatable_fields_ast = quote do
      @docs"""
      A simple helper funtion to return a list of translatable fields on this model
      """
      @spec translatable_fields :: List.t[Atom.t]
      def translatable_fields, do: unquote(fields)
    end

    translated_field_ast = Enum.map(fields, fn field ->
      quote do
        @docs"""
        Returns a translated value for the requested field in the optionally given locale.
        If locale was ommitted, it will use the current Gettext locale.
        This will cause a query to be run to get the translation.
        """
        def unquote(:"translated_#{(field)}")(%{__meta__: %{source: {_,translatable_type}}, id: translatable_id} = model, locale \\ nil) do
          locale = Atom.to_string(locale || String.to_atom(EctoTranslate.current_locale))
          record = EctoTranslate
          |> where(translatable_type: ^translatable_type, locale: ^locale, translatable_id: ^translatable_id, field: unquote(Atom.to_string(field)))
          |> unquote(repo).one

          case record do
            nil -> Map.get(model, unquote(field))
            record -> Map.get(record, :content)
          end
        end
      end
    end)

    translate_ast = quote do
      @docs"""
      Updates the model(s) that has/have been passed by replacing the content of the translatable fields with the optional locale given.
      If locale was ommited, it will use the current Gettext locale.
      This will cause a query to be run to get the translations.
      """
      @spec translate!(model :: Ecto.Schema.t | List.t[Ecto.Schema.t], locale :: Atom.t) :: Ecto.Schema.t | List.t[Ecto.Schema.t]
      def translate!(model, locale \\ nil)
      def translate!(%{__meta__: %{source: {_,translatable_type}}, id: translatable_id} = model, locale) do
        locale = Atom.to_string((locale || String.to_atom(EctoTranslate.current_locale)))

        translations = EctoTranslate
        |> where(translatable_type: ^translatable_type, translatable_id: ^translatable_id, locale: ^locale)
        |> unquote(repo).all
        |> Enum.map(fn record -> {String.to_atom(Map.get(record, :field)) , Map.get(record, :content)} end)
        |> Enum.into(%{})

        Map.merge(model, translations)
      end
      def translate!([], _), do: []
      def translate!(models, locale) when is_list(models) do
        locale = Atom.to_string((locale || String.to_atom(EctoTranslate.current_locale)))
        ids = Enum.map(models, fn model -> model.id end)
        %{__meta__: %{source: {_,translatable_type}}} = Enum.at(models, 0)

        translations = EctoTranslate
        |> where(translatable_type: ^translatable_type, locale: ^locale)
        |> where([t], t.translatable_id in ^ids)
        |> unquote(repo).all

        #FIXME this might not be the most optimized way to do this, but for now, it works :)
        Enum.map(models, fn model ->
          attributes = Enum.filter(translations, fn (translation) ->  translation.translatable_id == model.id end)
          |> Enum.map(fn record -> {String.to_atom(Map.get(record, :field)) , Map.get(record, :content)} end)
          |> Enum.into(%{})

          Map.merge(model, attributes)
        end)
      end
    end

    {translatable_fields_ast, {translated_field_ast, translate_ast}}
  end

  @translatable_id_type Application.get_env(:ecto_translate, :translatable_id_type, :integer)

  @doc """
  Returns translatable id type configured for application

  The id type can be configured by setting `:translatable_id_type` config for
  `:ecto_translate` otp application.

  ## Example
  ```elixir
    config ecto_translate,
      translatable_id_type: :string
  ```

  By default the is type is presumed as `:integer`
  """
  @spec translatable_id_type :: atom()
  def translatable_id_type, do: @translatable_id_type

  schema "translations" do
    field :translatable_id, @translatable_id_type
    field :translatable_type, :string
    field :locale, :string
    field :field, :string
    field :content, :string
    timestamps()
  end

  @repo Application.get_env(:ecto_translate, :repo)
  @required_fields ~w(translatable_id translatable_type locale field content)a

  @doc """
  Builds a changeset based on the `struct` and `params` and validates the required fields and given locale

  """
  @spec changeset(struct :: Ecto.Schema.t, params :: Map.t) :: Ecto.Changeset.t
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_locale
    |> unique_constraint(:translatable_id, name: :translations_translatable_id_translatable_type_locale_field_ind)
  end

  @doc """
  Creates the translations for the given fields in the database or will update those when they already exist.

  ## Example

      iex> %EctoTranslate.ExampleModel{title: "A title in english", description: "A description in english"}
      ...> |> EctoTranslate.Repo.insert!
      ...> |> EctoTranslate.set(locale: :de, title: "Eine deutche titel", description: "Ein deutsche umschreibung")
      [
        %EctoTranslate{__meta__: #Ecto.Schema.Metadata<:loaded, "translations">, content: "Eine deutche titel", field: "title", id: 241, inserted_at: #Ecto.DateTime<2016-07-01 21:09:11>, locale: "de", translatable_id: 221, translatable_type: "test_model", updated_at: #Ecto.DateTime<2016-07-01 21:09:11>},
        %EctoTranslate{__meta__: #Ecto.Schema.Metadata<:loaded, "translations">, content: "Ein deutsche umschreibung", field: "description", id: 242, inserted_at: #Ecto.DateTime<2016-07-01 21:09:11>, locale: "de", translatable_id: 221, translatable_type: "test_model", updated_at: #Ecto.DateTime<2016-07-01 21:09:11>}
      ]

  """
  @spec set(model :: Ecto.Schema.t, options :: List.t[{Atom.t, Any.t}]) :: :ok | {:error, List.t}
  def set(%{__meta__: %{source: {_,translatable_type}}, id: translatable_id} = model, [{:locale, locale} | options]) do
    params = %{
      translatable_type: translatable_type,
      translatable_id: translatable_id,
      locale: Atom.to_string(locale)
    }

    changesets = create_changesets(model, params, options)

    case validate_changesets(changesets) do
      {:ok, changesets} -> changesets |> upsert_translations
      error -> error
    end
  end

  @doc """
  An helper method to get the current Gettext locale
  """
  @spec current_locale :: String.t
  def current_locale, do: Gettext.get_locale(Application.get_env(:ecto_translate, :gettext))

  @doc """
  An helper method to get the known Gettext locales
  """
  @spec known_locales :: List.t[String.t]
  def known_locales, do: Gettext.known_locales(Application.get_env(:ecto_translate, :gettext))

  defp validate_changesets(changesets) do
    case Enum.filter(changesets, fn changeset -> !changeset.valid? end) do
      invalid when invalid == [] -> {:ok, changesets}
      _ -> {:error, Enum.map(changesets, fn changeset -> {changeset.changes.field, changeset.errors} end)}
    end
  end

  defp create_changesets(model, params, options) do
    options
    |> Enum.filter(fn {k, _v} -> Enum.member?(model.__struct__.translatable_fields, k) end)
    |> Enum.map(fn {field, content} ->
       params = Map.merge(params, %{field: Atom.to_string(field), content: content})
       EctoTranslate.changeset(%EctoTranslate{}, params)
    end)
  end

  defp validate_locale(%{changes: %{locale: locale}} = changeset) do
    case Enum.member?(EctoTranslate.known_locales, locale) do
      true  -> changeset
      false -> add_error(changeset, :locale, "The locale '#{locale}' is not supported, supported are: #{Enum.join(EctoTranslate.known_locales, ", ")}, if you think this is incorrect, make sure your Gettext.known_locales/1 knows about the locale you want to add...")
    end
  end
  defp validate_locale(changeset), do: changeset

  defp upsert_translations([]), do: :ok
  defp upsert_translations([changeset| changesets]) do
    case @repo.insert(changeset) do
      {:ok, cs} -> cs
      {:error, cs} -> cs |> update_translation
    end

    upsert_translations(changesets)
  end

  defp update_translation(%{changes: changes}) do
    record = EctoTranslate
    |> where(translatable_type: ^changes.translatable_type, translatable_id: ^changes.translatable_id, locale: ^changes.locale, field: ^changes.field)
    |> @repo.one!

    record = Ecto.Changeset.change(record, changes)
    @repo.update!(record)
  end
end
