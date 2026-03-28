defmodule ElixirMite.API.Customers do
  @moduledoc "Mite customers API."

  def list(client), do: Req.get(client, url: "/customers.json")
  def get(client, id), do: Req.get(client, url: "/customers/#{id}.json")

  def create(client, attrs),
    do: Req.post(client, url: "/customers.json", json: %{customer: attrs})

  def update(client, id, attrs),
    do: Req.patch(client, url: "/customers/#{id}.json", json: %{customer: attrs})

  def delete(client, id), do: Req.delete(client, url: "/customers/#{id}.json")
end
