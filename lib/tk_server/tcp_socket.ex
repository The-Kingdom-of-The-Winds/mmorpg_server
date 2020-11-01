defmodule TkServer.TCPSocket do
  @moduledoc """
  The TCPSocket is meant to only ONLY handle the TCP Socket for the Client. This is to isolate failure so that we can
  possibly recover from crashes while parsing or running game logic without dropping actively connected clients.

  This is an active tcp genserver, so can possibly be overwhelmed by backpressure. Should look into setting it as
  an active_once socket.
  """
  use GenServer, restart: :transient
  require Logger

  @initial_state %{socket: nil, client_id: nil}

  def start_link(socket, opts \\ []) do
    GenServer.start_link(__MODULE__, socket, opts)
  end

  def send_bytes(pid, data) do
    GenServer.cast(pid, {:send_bytes, data})
  end

  def init(socket) do
    {:ok, %{@initial_state | socket: socket}, {:continue, {:tcp_connect}}}
  end

  def handle_continue({:tcp_connect}, state) do
    Logger.info("TCP Socket Connected")

    client_id = init_client()
    send_hello(state.socket)

    {:noreply, %{state | client_id: client_id}}
  end

  def init_client() do
    client_id = UUID.uuid4()
    TkServer.ClientSupervisor.start_link({self(), client_id})

    client_id
  end

  @doc """
  Sends the magic hello bytes to acknowledge the connection. The client will not proceed without this. This gets sent
  when transfering servers as well, which doesn't seem to cause any problems.
  """
  def send_hello(socket) do
    hello = [<<0xAA, 0x00, 0x13, 0x7E, 0x1B>>, "CONNECTED SERVER", <<0x0A>>]
    :gen_tcp.send(socket, hello)
  end

  def handle_info({:tcp, _socket, data}, state) do
    Logger.debug("Received bytes from client\n#{inspect(data, base: :hex)}")
    TkServer.TCPConn.from_client(state.client_id, data)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Logger.info("TCP Socket Closed")
    # TODO: Let the conn and client know we are shutting down

    Process.exit(self(), :normal)
  end

  def handle_cast({:send_bytes, data}, %{socket: socket} = state) do
    Logger.debug("Sending bytes to client\n#{inspect(data, base: :hex)}")
    :gen_tcp.send(socket, data)
    {:noreply, state}
  end
end
