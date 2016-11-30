defmodule RapidApi do

  @doc """
  Calls the specified package and base, passing all arguments provided.

  Returns a Map of the payload.
  """
  @spec call(String.t, String.t, map()) :: map()
  def call(pack, base, args \\ %{}) do
    { base_url, token, project } = get_vars
    { :ok, encoded } = Poison.encode(args)

    params = [
      body: encoded,
      basic_auth: { project, token },
      headers: [
        "User-Agent": "RapidAPIConnect_Elixir",
        "Content-Type": "application/json"
      ]
    ]

    request = 
      base_url <> "/#{pack}/#{base}"
      |> HTTPotion.post!(params)

    { :ok, parsed } = Poison.decode(request.body)
    parsed["payload"]
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

end
