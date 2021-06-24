defmodule UserCounterTest do
  use ExUnit.Case, async: true

  # TESTS FAIL!
  # Some runs, "initializes to zero" goes first and everything
  # passes. Other runs, "increment" goes first, so "initializes"
  # sees a count of 2.

  test "initializes to zero" do
    assert UserCounter.count() == 0
  end

  test "increments" do
    assert UserCounter.increment()
    assert UserCounter.count() == 1

    assert UserCounter.increment()
    assert UserCounter.count() == 2
  end
end
