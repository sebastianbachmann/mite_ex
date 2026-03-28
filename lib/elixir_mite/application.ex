defmodule ElixirMite.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ElixirMite.TUI.App, []}
    ]

    opts = [strategy: :one_for_one, name: ElixirMite.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
