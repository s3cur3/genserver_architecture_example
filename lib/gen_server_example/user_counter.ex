defmodule UserCounter do
  @moduledoc "Tracks the number of users logged in to our web app"
  use GenServer

  def start_link(opts \\ []) do
    server_name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, 0, name: server_name)
  end

  def increment(server \\ __MODULE__), do: GenServer.call(server, :increment)
  def decrement(server \\ __MODULE__), do: GenServer.call(server, :decrement)

  def count(server \\ __MODULE__), do: GenServer.call(server, :count)

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
