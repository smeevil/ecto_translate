defmodule EctoTranslate.ExampleModel do
  use Ecto.Schema

  import Ecto.Query
  import EctoTranslate.Gettext

  use EctoTranslate, [:title, :description]

  schema "test_model" do
    field(:title, :string)
    field(:description, :string)
  end

  # just so we have something to extract
  def example_text do
    gettext("Hello World")
  end
end
