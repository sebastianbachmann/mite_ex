defmodule ElixirMite.API.Client do
  @moduledoc """
  Req-based HTTP client for the mite.de API.

  Builds a base Req request with authentication headers and
  the account-specific base URL.
  """

  @user_agent "elixir-mite/0.1.0 (https://github.com/your/elixir-mite)"

  def new(account_name, api_key) do
    Req.new(
      base_url: "https://#{account_name}.mite.de",
      headers: [
        {"X-MiteApiKey", api_key},
        {"User-Agent", @user_agent},
        {"Content-Type", "application/json"}
      ],
      receive_timeout: 10_000
    )
  end
end
