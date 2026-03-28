defmodule ElixirMite.API.Services do
  @moduledoc "Mite services API."

  def list(client), do: Req.get(client, url: "/services.json")
  def get(client, id), do: Req.get(client, url: "/services/#{id}.json")
  def create(client, attrs), do: Req.post(client, url: "/services.json", json: %{service: attrs})

  def update(client, id, attrs),
    do: Req.patch(client, url: "/services/#{id}.json", json: %{service: attrs})

  def delete(client, id), do: Req.delete(client, url: "/services/#{id}.json")
end
