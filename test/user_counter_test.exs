defmodule UserCounterTest do
  use ExUnit.Case, async: true

  test "UserCounter smoke test" do
    {:ok, genserver} =
      UserCounter.start_link(
        name: :user_counter_smoke_test,
        garbage_collection_ms: 1_000_000,
        max_age_ms: 1_000_000
      )

    assert UserCounter.empty?(genserver)
    assert UserCounter.empty?(genserver, :africa)

    UserCounter.put(genserver, "user1", :north_america)
    UserCounter.put(genserver, "user2", :asia)
    UserCounter.put(genserver, "user3", :africa)
    UserCounter.put(genserver, "user2", :africa)

    assert UserCounter.count(genserver) == 3
    assert UserCounter.count(genserver, :africa) == 2
    refute UserCounter.empty?(genserver)
    refute UserCounter.empty?(genserver, :africa)

    UserCounter.drop(genserver, "user3")
    assert UserCounter.count(genserver) == 2
    assert UserCounter.count(genserver, :africa) == 1
  end

  test "UserCounter garbage collection" do
    {:ok, genserver} =
      UserCounter.start_link(
        name: :garbage_collection_test,
        garbage_collection_ms: 10,
        max_age_ms: 1
      )

    UserCounter.put(genserver, "user1", :north_america)
    :timer.sleep(10)
    assert UserCounter.empty?(genserver)
  end
end
