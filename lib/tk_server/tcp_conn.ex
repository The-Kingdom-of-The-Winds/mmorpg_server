defmodule TkServer.TCPConn do
  alias TkServer.{TCPSocket}
  alias TCPProtocol.{Encoder, Decoder}
  use GenServer
  require Logger

  @initial_state %{server_seq: 2, client_seq: 0, stream_key: nil, client_id: nil, socket_pid: nil}

  def start_link({socket_pid, client_id}, _opts \\ []) do
    GenServer.start_link(__MODULE__, {socket_pid, client_id}, name: via_tuple(client_id))
  end

  def via_tuple(client_id), do: {:via, Registry, {TkServer.ConnRegistry, client_id}}

  def from_client(client_id, bytes) do
    GenServer.cast(via_tuple(client_id), {:from_client, bytes})
  end

  def send_conn([], _), do: :ok

  def send_conn(msgs, client_id) when is_list(msgs) do
    Enum.each(msgs, &send_conn(&1, client_id))
  end

  def send_conn(msg, client_id) do
    GenServer.cast(via_tuple(client_id), {:send, msg})
  end

  def set_stream_key(client_id, stream_key) do
    GenServer.call(via_tuple(client_id), {:stream_key, stream_key})
  end

  def init({socket_pid, client_id}) do
    Logger.info("TCP Conn Started for #{client_id}")

    state = %{@initial_state | client_id: client_id, socket_pid: socket_pid}
    {:ok, state}
  end

  def handle_call({:stream_key, stream_key}, _from, state) do
    Logger.info("Setting stream key to #{stream_key}")
    {:reply, {:ok}, %{state | stream_key: stream_key}}
  end

  def handle_cast({:from_client, bytes}, state) do
    data = Decoder.from_bytes(bytes, state.stream_key)
    Client.input(state.client_id, data)

    {:noreply, state}
  end

  def handle_cast({:send, msg}, state) do
    data = Encoder.from_msg(msg, state.server_seq, state.stream_key)
    TCPSocket.send_bytes(state.socket_pid, data)

    server_seq =
      case rem(state.server_seq, 255) do
        0 -> 1
        seq -> seq + 1
      end

    {:noreply, %{state | server_seq: server_seq}}
  end
end
