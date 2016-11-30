defmodule RapidApi do

  @doc """
  Calls the specified package and base, passing all arguments provided.

  Returns a Map of the payload.
  """
  @spec call(String.t, String.t, map()) :: map()
  def call(pack, base, args \\ %{}) when is_bitstring(pack) and is_bitstring(base) and is_map(args) do
    base_url = Application.get_env(:rapid_api, :base_url, "https://rapidapi.io/connect")
    base_url <> "/#{pack}/#{base}"
    |> HTTPotion.post!(get_params(args))
    |> Map.get(:body)
    |> Poison.decode()
    |> ok
    |> Map.get("payload")
  end
  
  defp get_vars do
    base_url = Application.get_env(:rapid_api, :base_url, "https://rapidapi.io/connect")
    case token = Application.get_env(:rapid_api, :token) do
      nil -> raise "No API token defined in config"
      token -> token
    end
    case project = Application.get_env(:rapid_api, :project) do
      nil -> raise "No project defined in config"
      project -> project
    end
    { base_url, token, project }
  end

  defp get_params(args) do
    { _base_url, token, project } = get_vars
    { :ok, encoded } = Poison.encode(args)
    [
      body: encoded,
      basic_auth: { project, token },
      headers: [
        "User-Agent": "RapidAPIConnect_Elixir",
        "Content-Type": "application/json"
      ]
    ]
  end
  
  defp ok({:ok, resp}), do: resp

end
