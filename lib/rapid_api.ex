defmodule RapidApi do

  @doc """
  Creates a synchronous call to the specified package and base, passing all arguments provided.

  Returns a Map of the payload.
  """
  @spec call(String.t, String.t, map()) :: map()
  def call(pack, base, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_map(args) do
    base_url() <> "/connect/#{pack}/#{base}"
    |> HTTPotion.post!(get_params(args))
    |> Map.get(:body)
    |> Poison.decode
    |> ok
    |> Map.get("payload")
  end

  @doc """
  Creates an asynchronous call to the specified package and base, passing all arguments provided. When an answer is returned, sends the payload to the specified receiver pid.

  Returns :ok
  """
  @spec call_async(String.t, String.t, pid(), map()) :: atom()
  def call_async(pack, base, receiver_pid, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_pid(receiver_pid) and is_map(args) do
    
    base_url() <> "/connect/#{pack}/#{base}"
    |> HTTPotion.post!(get_params(args, receiver_pid))

    :ok
  end

  def async_worker(receiver_pid) when is_pid(receiver_pid) do
    receive do
      %HTTPotion.AsyncChunk{chunk: data} ->
        decoded = 
          data
          |> Poison.decode
          |> ok
          |> Map.get("payload")
        send(receiver_pid, decoded)
    end
  end

  defp get_vars do
    case token = Application.get_env(:rapid_api, :token) do
      nil -> raise "No API token defined in config"
      token -> token
    end
    case project = Application.get_env(:rapid_api, :project) do
      nil -> raise "No project defined in config"
      project -> project
    end
    {token, project}
  end

  defp base_url, do: Application.get_env(:rapid_api, :base_url, "https://rapidapi.io")
  
  defp get_params(args) do
    {token, project} = get_vars
    {:ok, encoded} = Poison.encode(args)

    [
      body: encoded,
      basic_auth: {project, token},
      headers: [
        "User-Agent": "RapidAPIConnect_Elixir",
        "Content-Type": "application/json"
      ]
    ]
  end

  defp get_params(args, receiver_pid) do
    {token, project} = get_vars
    {:ok, encoded} = Poison.encode(args)

    worker_pid = spawn(__MODULE__, :async_worker, [receiver_pid])
    [
      body: encoded,
      stream_to: worker_pid,
      basic_auth: {project, token},
      headers: [
        "User-Agent": "RapidAPIConnect_Elixir",
        "Content-Type": "application/json"
      ]
    ]
  end
  
  defp ok({:ok, resp}), do: resp

end
