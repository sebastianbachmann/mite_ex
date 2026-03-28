defmodule ElixirMite.Config.Loader do
  @moduledoc """
  Loads configuration from ~/.config/elixir-mite/config.toml.

  Expected format:

      [account]
      name = "your_account"
      api_key = "your_api_key"
  """

  @config_path Path.expand("~/.config/elixir-mite/config.toml")

  def load do
    with {:ok, content} <- File.read(@config_path),
         {:ok, config} <- Toml.decode(content) do
      {:ok, config}
    else
      {:error, :enoent} -> {:error, "Config file not found at #{@config_path}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def load! do
    case load() do
      {:ok, config} -> config
      {:error, reason} -> raise "Failed to load config: #{inspect(reason)}"
    end
  end
end
