defmodule ElixirMite.API.Projects do
  @moduledoc "Mite projects API."

  def list(client), do: Req.get(client, url: "/projects.json")
  def get(client, id), do: Req.get(client, url: "/projects/#{id}.json")
  def create(client, attrs), do: Req.post(client, url: "/projects.json", json: %{project: attrs})

  def update(client, id, attrs),
    do: Req.patch(client, url: "/projects/#{id}.json", json: %{project: attrs})

  def delete(client, id), do: Req.delete(client, url: "/projects/#{id}.json")
end
