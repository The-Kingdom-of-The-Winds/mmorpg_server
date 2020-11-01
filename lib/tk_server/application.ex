defmodule TkServer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    init_ets()

    import Supervisor.Spec

    children = [
      supervisor(TkServer.Repo, []),
      {Game.World, :ok},
      {Game.System.Input, :ok},
      {Game.System.CameraRender, :ok},
      {Game.System.Player, :ok},
      {Task.Supervisor, name: Scripts.Supervisor},
      {Registry, keys: :unique, name: TkServer.ConnRegistry},
      {Registry, keys: :unique, name: TkServer.ClientRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: TkServer.TCPSocketSupervisor},
      {TkServer.TCPServer, 2000}
    ]

    opts = [strategy: :one_for_one, name: TkServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def init_ets() do
    :ets.new(:map_cache, [:named_table, :public, :set])
    :ets.new(:client_key_cache, [:named_table, :public, :set])
  end
end
