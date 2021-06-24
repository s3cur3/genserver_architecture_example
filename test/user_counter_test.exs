defmodule UserCounterTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, counter} = UserCounter.start_link(name: :initialize_test)
    %{counter: counter}
  end

  test "initializes to zero", %{counter: counter} do
    assert UserCounter.count(counter) == 0
  end

  test "increments", %{counter: counter} do
    assert UserCounter.increment(counter)
    assert UserCounter.count(counter) == 1

    assert UserCounter.increment(counter)
    assert UserCounter.count(counter) == 2
  end

  test "decrements, but does not go negative", %{counter: counter} do
    assert UserCounter.decrement(counter)
    assert UserCounter.count(counter) == 0

    assert UserCounter.increment(counter)
    assert UserCounter.increment(counter)
    assert UserCounter.increment(counter)

    assert UserCounter.decrement(counter)
    assert UserCounter.count(counter) == 2
  end
end
