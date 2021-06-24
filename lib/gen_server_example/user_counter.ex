defmodule UserCounter do
  @moduledoc "Tracks the number of users logged in to our web app"
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, 0, name: __MODULE__)

  def increment(), do: GenServer.call(__MODULE__, :increment)
  def decrement(), do: GenServer.call(__MODULE__, :decrement)

  def count, do: GenServer.call(__MODULE__, :count)

  # BAD!
  def reset, do: GenServer.call(__MODULE__, :reset)

  ############## GenServer Implementation ################
  @impl GenServer
  def init(initial_count) when is_integer(initial_count) do
    {:ok, initial_count}
  end

  @impl GenServer
  def handle_call(:count, _from, current_count) do
    {:reply, current_count, current_count}
  end

  @impl GenServer
  def handle_call(:increment, _from, current_count) do
    {:reply, :ok, current_count + 1}
  end

  @impl GenServer
  def handle_call(:decrement, _from, current_count) do
    {:reply, :ok, current_count - 1}
  end

  @impl GenServer
  def handle_call(:reset, _from, _count) do
    {:reply, :ok, 0}
  end
end
