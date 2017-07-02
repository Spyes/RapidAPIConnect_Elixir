defmodule RapidApi.Socket do
  alias Phoenix.Channels.GenSocketClient
  @behaviour GenSocketClient

  def start_link(token, receiver_pid, params \\ []) do
    start = GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      ["wss://webhooks.rapidapi.io/socket/websocket?token=#{token}", token, params, receiver_pid]
    )
  end

  def init([url, token, params, receiver_pid]) do
    state = %{first_join: true, ping_ref: 1, token: token, params: params, receiver: receiver_pid}
    {:connect, url, state}
  end

  def handle_call({:save_params, pid}, state) do
    {:noreply, Map.put(state, "receiver", pid)}
  end
  
  def handle_connected(transport, state) do
    GenSocketClient.join(transport, "users_socket:#{state.token}", state.params)
    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Process.send_after(self(), :connect, :timer.seconds(1))
    {:ok, state}
  end

  def handle_joined(topic, _payload, _transport, state) do
    if state.first_join do
      :timer.send_interval(:timer.seconds(30), self(), :ping_server)
      {:ok, %{state | first_join: false, ping_ref: 1}}
    else
      {:ok, %{state | ping_ref: 1}}
    end
  end

  def handle_join_error(topic, payload, _transport, state) do
    send state.receiver, {:error, payload}
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Process.send_after(self(), {:join, topic}, :timer.seconds(1))
    {:ok, state}
  end

  def handle_message(topic, event, payload, _transport, state) do
    case event do
      "new_msg" ->
        if payload["token"] do
          send state.receiver, {:new_msg, payload["body"]}
        else
          send state.receiver, {:error, payload["body"]["msg"]["message"]}
        end
      "joined" -> send state.receiver, :joined
      _ -> send state.receiver, {:error, payload}
    end
    {:ok, state}
  end

  def handle_reply("ping", _ref, %{"status" => "ok"} = payload, _transport, state) do
    IO.puts "ping: "
    IO.puts inspect payload
    {:ok, state}
  end
  def handle_reply(topic, _ref, payload, _transport, state) do
    IO.puts inspect payload
    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    {:connect, state}
  end
  def handle_info({:join, topic}, transport, state) do
    case GenSocketClient.join(transport, topic) do
      {:error, reason} ->
        Process.send_after(self(), {:join, topic}, :timer.seconds(1))
      {:ok, _ref} -> :ok
    end
    {:ok, state}
  end
  def handle_info(:ping_server, transport, state) do
    GenSocketClient.push(transport, "phoenix", "heartbeat", %{})
    {:ok, %{state | ping_ref: state.ping_ref + 1}}
  end
  def handle_info(message, _transport, state) do
    {:ok, state}
  end
end

