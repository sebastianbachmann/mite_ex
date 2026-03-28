defmodule ElixirMite.API.TimeEntries do
  @moduledoc "Mite time entries API."

  def list(client, params \\ []), do: Req.get(client, url: "/time_entries.json", params: params)
  def get(client, id), do: Req.get(client, url: "/time_entries/#{id}.json")

  def create(client, attrs),
    do: Req.post(client, url: "/time_entries.json", json: %{time_entry: attrs})

  def update(client, id, attrs),
    do: Req.patch(client, url: "/time_entries/#{id}.json", json: %{time_entry: attrs})

  def delete(client, id), do: Req.delete(client, url: "/time_entries/#{id}.json")
end
