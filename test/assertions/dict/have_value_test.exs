defmodule Dict.HaveValueTest do

  use ExUnit.Case, async: true

  defmodule SomeSpec do
    use ESpec, async: true

    subject %{a: 1, b: 2}
    
    context "Success" do
      it do: should have_value 1
      it do: should_not have_value 3
    end

    context "Error" do
      it do: should_not have_value 1
      it do: should have_value 3
    end
  end

  setup_all do
    examples = ESpec.Runner.run_examples(SomeSpec.examples)
    { :ok,
      success: Enum.slice(examples, 0, 1),
      errors: Enum.slice(examples, 2, 3)
    }
  end

  test "Success", context do
    Enum.each(context[:success], fn(ex) ->
      assert(ex.status == :success)
    end)
  end

  test "Errors", context do
    Enum.each(context[:errors], fn(ex) ->
      assert(ex.status == :failure)
    end)
  end

end
