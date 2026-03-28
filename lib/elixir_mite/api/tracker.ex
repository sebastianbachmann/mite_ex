defmodule ElixirMite.API.Tracker do
  @moduledoc """
  Mite time tracker API.

  The tracker represents the currently running timer. Only one timer
  can be active at a time per user.
  """

  def get(client), do: Req.get(client, url: "/tracker.json")

  def start(client, time_entry_id),
    do: Req.patch(client, url: "/tracker/#{time_entry_id}.json")

  def stop(client, time_entry_id),
    do: Req.delete(client, url: "/tracker/#{time_entry_id}.json")
end
