# RapidApi

Easily connect to RapidAPI blocks from your Elixir application.

## Installation

  1. Add `rapid_api` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rapid_api, "~> 1.0.1"}]
    end
    ```

  2. Ensure `rapid_api` is started before your application:

    ```elixir
    def application do
      [applications: [:rapid_api]]
    end
    ```

  3. Add your configuration to your config/config.exs
  
      ```elixir
      config :rapid_api,
        base_url: "https://rapidapi.io", # optional - defaults to this URL
        token: "your-rapid-api-token",
        project: "your-rapid-api-project"
      ```
      
## Usage

### Synchronous calls

Connecting to RapidAPI is very simple. The following code makes a synchronous call to the getPictureOfTheDay function of the NasaAPI package, passing it the date parameter:

```elixir
RapidAPI.call("NasaAPI", "getPictureOfTheDay", %{date: "1997-07-01"})
```
    
This will return a Map of the API response.

### Asynchronous calls

To create an asynchronous call, you must first define a process that will receive the payload:

```elixir
receiver = fn ->
    receive do
        data -> IO.puts inspect data
    end
end
receiver_pid = spawn(receiver)
```

Then use the `call_async` function, passing it the relevant information as well as the receiver process's pid:

```elixir
RapidApi.call_async("NasaAPI", "getPictureOfTheDay", receiver_pid, %{date: "1997-07-01"})
```

This will return `:ok` and once the request has returned, will `send` the data to the specified process.

## License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
