defmodule RapidApi do

  @doc """
  Calls the specified package and base, passing all arguments provided.

  Returns a Map of the payload.
  """
  @spec call(String.t, String.t, map()) :: map()
  def call(pack, base, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_map(args) do
    base_url() <> "/connect/#{pack}/#{base}"
    |> HTTPotion.post!(get_params(args))
    |> Map.get(:body)
    |> Poison.decode()
    |> ok
    |> Map.get("payload")
  end

  def call_async(pack, base, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_map(args) do
    {:ok, worker_pid} =
      base_url()
      |> HTTPotion.spawn_worker_process()

    {token, project} = get_vars
    {:ok, encoded} = Poison.encode(args)
    params = [
      body: encoded,
      direct: worker_pid,
      stream_to: self,
      basic_auth: {project, token},
      headers: [
        "User-Agent": "RapidAPIConnect_Elixir",
        "Content-Type": "application/json"
      ]
    ]
    
    base_url() <> "/connect/#{pack}/#{base}"
    |> HTTPotion.post!(params)

    receive do
      %HTTPotion.AsyncChunk{chunk: new_data} -> IO.puts inspect new_data
    end
    :ok
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
  
  defp ok({:ok, resp}), do: resp

end
