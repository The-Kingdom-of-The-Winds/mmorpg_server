defmodule TkServer.ClientSupervisor do
  use Supervisor

  def start_link({tcp_pid, client_id}) do
    Supervisor.start_link(__MODULE__, {tcp_pid, client_id})
  end

  @impl true
  def init({tcp_pid, client_id}) do
    children = [
      {TkServer.TCPConn, {tcp_pid, client_id}},
      {Client, {client_id}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
