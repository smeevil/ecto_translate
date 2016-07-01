defmodule EctoTranslateTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoTranslate.Repo)
    test_record = EctoTranslate.Repo.insert!(%EctoTranslate.ExampleModel{title: "A title in english", description: "A description in english"})
    {:ok, test_record: test_record}
  end

  @valid_attributes [locale: :nl, title: "Een nederlandse titel",  description: "Een nederlandse beschrijving"]

  test "It should return errors for translated fields if the content is not a string", state do
    result = EctoTranslate.set(state[:test_record], locale: :nl, title: 42, description: :this_is_wrong)
    assert {:error,[
             {"title", [content: {"is invalid", [type: :string]}]},
             {"description", [content: {"is invalid", [type: :string]}]}
           ]} == result
  end

  test "It should return errors for translated fields if the locale is not supported", state do
    result = EctoTranslate.set(state[:test_record], locale: :gibberish, title: "test", description: "test")
    assert {:error, [{"title", [locale: {"The locale 'gibberish' is not supported, supported are: de, nl, if you think this is incorrect, make sure your Gettext.known_locales/1 knows about the locale you want to add...", []}]}, {"description", [locale: {"The locale 'gibberish' is not supported, supported are: de, nl, if you think this is incorrect, make sure your Gettext.known_locales/1 knows about the locale you want to add...", []}]}]} == result
  end

  test "It can create translated fields", state do
    :ok = EctoTranslate.set(state[:test_record], @valid_attributes)

    [first, second] = EctoTranslate |> EctoTranslate.Repo.all
    assert "nl" == first.locale
    assert "title" == first.field
    assert "Een nederlandse titel" == first.content

    assert "nl" == second.locale
    assert "description" == second.field
    assert "Een nederlandse beschrijving" == second.content
  end

  test "it returns translated fields", state do
    EctoTranslate.set(state[:test_record], @valid_attributes)
    assert "Een nederlandse titel" == EctoTranslate.ExampleModel.translated_title(state[:test_record], :nl)
  end

  test "it returns a fallback when for non translated fields", state do
    assert state[:test_record].title == EctoTranslate.ExampleModel.translated_title(state[:test_record], :nl)
  end

  test "it should translate the state[:test_record] inline", state do
    EctoTranslate.set(state[:test_record], @valid_attributes)
    record = EctoTranslate.ExampleModel.translate!(state[:test_record], :nl)
    assert "Een nederlandse titel" == record.title
    assert "Een nederlandse beschrijving" == record.description
  end

  test "it should translate the state[:test_record] inline using the current gettext locale", state do
    EctoTranslate.set(state[:test_record], locale: :de, title: "Eine deutche titel", description: "Ein deutsche umschreibung")
    EctoTranslate.set(state[:test_record], @valid_attributes)
    Gettext.put_locale(EctoTranslate.Gettext, "nl")
    record = EctoTranslate.ExampleModel.translate!(state[:test_record])
    assert "Een nederlandse titel" == record.title
    assert "Een nederlandse beschrijving" == record.description

    Gettext.put_locale(EctoTranslate.Gettext, "de")
    record = EctoTranslate.ExampleModel.translate!(state[:test_record])
    assert "Eine deutche titel" == record.title
    assert "Ein deutsche umschreibung" == record.description
  end

  test "it should update an existing translation", state do
    :ok = EctoTranslate.set(state[:test_record], locale: :de, title: "Eine neue deutche titel", description: "Ein neue deutsche umschreibung")
    1 = EctoTranslate.ExampleModel |> EctoTranslate.Repo.all |> Enum.count
    record = EctoTranslate.ExampleModel |> limit(1) |> EctoTranslate.Repo.one |> EctoTranslate.ExampleModel.translate!(:de)
    "Eine neue deutche titel" = record.title

    :ok = EctoTranslate.set(state[:test_record], locale: :de, title: "Eine deutche titel", description: "Ein deutsche umschreibung")
    1 = EctoTranslate.ExampleModel |> EctoTranslate.Repo.all |> Enum.count
    record = EctoTranslate.ExampleModel |> limit(1) |> EctoTranslate.Repo.one |> EctoTranslate.ExampleModel.translate!(:de)
    "Eine deutche titel" = record.title
  end
end
