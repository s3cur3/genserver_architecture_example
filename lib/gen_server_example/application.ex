defmodule GenServerExample.Application do
  @moduledoc """
  Just starts our one user counter GenServer
  """
  use Application
  require Logger

  def start(_type, _args) do
    Logger.configure(level: :debug)
    Logger.info("Starting up...")

    Supervisor.start_link([UserCounter], strategy: :one_for_one, name: Example.Supervisor)
  end
end
