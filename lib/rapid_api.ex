defmodule RapidApi do

  @doc """
  Creates a synchronous call to the specified package and base, passing all arguments provided.

  Returns {:ok, payload} or {:error, reason}.
  """
  @spec call(String.t, String.t, list()) :: list()
  def call(pack, base, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_list(args) do
    base_url() <> "/connect/#{pack}/#{base}"
    |> HTTPoison.post!({:form, args}, headers())
    |> Map.get(:body)
    |> decode_response
  end

  @doc """
  Creates an asynchronous call to the specified package and base, passing all arguments provided.
  When an answer is returned, sends the payload to the specified receiver pid.

  Returns :ok
  """
  @spec call_async(String.t, String.t, pid(), list()) :: atom()
  def call_async(pack, base, receiver_pid, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_pid(receiver_pid) and is_list(args) do
    worker = spawn(RapidApi, :async_worker, [receiver_pid])

    base_url() <> "/connect/#{pack}/#{base}"
    |> HTTPoison.post!({:form, args}, headers(), stream_to: worker)
    :ok
  end

  def async_worker(receiver_pid) when is_pid(receiver_pid) do
    receive do
      %HTTPoison.AsyncChunk{chunk: data} ->
        send(receiver_pid, decode_response(data))
    end
  end

  @doc """
  Listens for real-time events by opening a websocket to RapidAPI.

  Returns :ok
  """
  @spec listen(String.t, String.t, pid(), list()) :: atom()
  def listen(pack, base, receiver_pid, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_pid(receiver_pid) and is_list(args) do
    {token, project} = get_vars()
    uid = "#{pack}.#{base}_#{project}:#{token}"
    token =
      get_token_url(uid)
      |> HTTPoison.get!
      |> Map.get(:body)
      |> Poison.decode!
      |> Map.get("token")

    {:ok, pid} = RapidApi.Listen.start_link(self(), websocket_url(token))
    RapidApi.Listen.join(pid, "users_socket:#{token}", %{"token" => token})
    :ok
  end
  
  defp decode_response(data) do
    case Poison.decode(data) do
      {:ok, decoded} ->
        payload = Map.get(decoded, "payload", "")
        case Poison.decode(payload) do
          {:ok, pl} -> {:ok, pl}
          {:error, _} -> {:ok, payload}
        end
      {:error, _} -> {:error, data}
    end
  end
  
  defp get_vars do
    case token = Application.get_env(:rapid_api, :key) do
      nil -> raise "No API token defined in config"
      token -> token
    end
    case project = Application.get_env(:rapid_api, :project) do
      nil -> raise "No project defined in config"
      project -> project
    end
    {token, project}
  end

  defp base_url, do: "https://rapidapi.io"
  #defp get_token_url(user_id), do: "https://webhooks.rapidapi.com/api/get_token?user_id=#{user_id}"
  #defp websocket_url(token), do: "wss://webhooks.rapidapi.com/socket/websocket?token=#{token}"
  defp get_token_url(user_id), do: "http://localhost:4000/api/get_token?user_id=#{user_id}"
  defp websocket_url(token), do: "ws://localhost:4000/socket/websocket?token=#{token}"

  defp headers do
    {token, project} = get_vars()
    encoded = Base.encode64("#{project}:#{token}")
    [
      "Authorization": "Basic #{encoded}",
      "User-Agent": "RapidAPIConnect_Elixir"
    ]
  end

end
