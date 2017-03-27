defmodule RapidApi.Mixfile do
  use Mix.Project

  def project do
    [app: :rapid_api,
     version: "1.0.1",
     elixir: "~> 1.3",
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:httpoison, :poison, :websocket_client]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.10.0"},
      {:poison, "~> 3.0"},
      {:websocket_client, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Easily connect to RapidAPI blocks.
    """
  end
  
  defp package do
    [
      name: :rapid_api,
      licenses: ["MIT"],
      maintainers: ["Lewis Nitzberg"],
      links: %{"GitHub" => "https://github.com/Spyes/RapidAPIConnect_Elixir"}
    ]
  end
end
