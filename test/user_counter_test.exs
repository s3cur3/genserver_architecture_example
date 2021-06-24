defmodule UserCounterTest do
  use ExUnit.Case, async: true

  test "initializes to zero" do
    UserCounter.reset() # BAD
    assert UserCounter.count() == 0
  end

  test "increments" do
    UserCounter.reset() # BAD
    assert UserCounter.increment()
    assert UserCounter.count() == 1

    assert UserCounter.increment()
    assert UserCounter.count() == 2
  end
end
