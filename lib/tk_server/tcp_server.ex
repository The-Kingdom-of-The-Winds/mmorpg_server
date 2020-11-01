defmodule TkServer.TCPServer do
  use Task

  def start_link(port) do
    Task.start_link(__MODULE__, :accept, [port])
  end

  def accept(port) do
    tcp_opts = [:binary, packet: 0, active: true, reuseaddr: true]
    {:ok, listen_socket} = :gen_tcp.listen(port, tcp_opts)

    do_accept(listen_socket)
  end

  defp do_accept(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    {:ok, pid} = DynamicSupervisor.start_child(TkServer.TCPSocketSupervisor, {TkServer.TCPSocket, socket})

    :gen_tcp.controlling_process(socket, pid)
    do_accept(listen_socket)
  end
end
