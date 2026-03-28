defmodule ElixirMite.TUI.App do
  @moduledoc """
  Main TUI application using the ExRatatui.App behaviour.
  """
  use ExRatatui.App

  alias ElixirMite.API.{Client, Tracker, TimeEntries}
  alias ElixirMite.Config.Loader
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, List, Paragraph, Tabs}

  @tabs ["Dashboard", "Time Entries", "Projects", "Customers", "Services"]
  @refresh_interval 10_000

  @impl true
  def mount(_opts) do
    case Loader.load() do
      {:ok, %{"account" => %{"name" => name, "api_key" => api_key}}} ->
        client = Client.new(name, api_key)
        send(self(), :fetch_data)
        send(self(), :tick)

        {:ok,
         %{
           tab: 0,
           client: client,
           tracker: nil,
           time_entries: [],
           error: nil,
           loading: true,
           tick: 0
         }}

      {:error, reason} ->
        {:ok,
         %{
           tab: 0,
           client: nil,
           tracker: nil,
           time_entries: [],
           error: "Config error: #{reason}",
           loading: false,
           tick: 0
         }}
    end
  end

  @impl true
  def render(state, frame) do
    area = %Rect{x: 0, y: 0, width: frame.width, height: frame.height}

    [header, body, footer] =
      Layout.split(area, :vertical, [
        {:length, 3},
        {:min, 0},
        {:length, 1}
      ])

    tabs = %Tabs{
      titles: @tabs,
      selected: state.tab,
      highlight_style: %Style{fg: :cyan, modifiers: [:bold]},
      block: %Block{title: " elixir-mite ", borders: [:all], border_type: :rounded}
    }

    content = render_tab(state, body)

    status_text =
      cond do
        state.error -> " Error: #{state.error}"
        state.loading -> " Loading..."
        true -> " Tab/←/→: switch  n: new  e: edit  d: delete  r: refresh  q: quit"
      end

    status_style =
      cond do
        state.error -> %Style{fg: :red}
        state.loading -> %Style{fg: :yellow}
        true -> %Style{fg: :dark_gray}
      end

    status = %Paragraph{text: status_text, style: status_style}

    [{tabs, header}, {content, body}, {status, footer}]
  end

  # --- Tab renderers ---

  defp render_tab(%{error: err} = _state, _area) when not is_nil(err) do
    %Paragraph{
      text: err,
      style: %Style{fg: :red},
      block: %Block{title: " Error ", borders: [:all], border_type: :rounded}
    }
  end

  defp render_tab(%{tab: 0} = state, _area), do: render_dashboard(state)
  defp render_tab(%{tab: 1} = state, _area), do: render_time_entries(state)
  defp render_tab(%{tab: 2}, _area), do: placeholder("Projects")
  defp render_tab(%{tab: 3}, _area), do: placeholder("Customers")
  defp render_tab(%{tab: 4}, _area), do: placeholder("Services")

  defp render_dashboard(state) do
    tracker_text =
      case state.tracker do
        nil ->
          "No active tracker\n\nPress t to start tracking."

        %{"tracking_time_entry" => entry} ->
          minutes = entry["minutes"] || 0
          note = entry["note"] || "(no note)"
          project = entry["project_name"] || "No project"
          "● Tracking: #{note}\n  Project: #{project}\n  Time: #{format_minutes(minutes)}"
      end

    today_minutes =
      state.time_entries
      |> Enum.filter(&(Date.to_string(Date.utc_today()) == &1["date_at"]))
      |> Enum.reduce(0, &(&1["minutes"] + &2))

    summary = "Today: #{format_minutes(today_minutes)}  |  Entries: #{length(state.time_entries)}"

    %Paragraph{
      text: "#{tracker_text}\n\n#{summary}",
      style: %Style{fg: if(state.tracker, do: :green, else: :white)},
      block: %Block{
        title: " Dashboard ",
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: if(state.tracker, do: :green, else: :dark_gray)}
      }
    }
  end

  defp render_time_entries(%{time_entries: [], loading: true}) do
    %Paragraph{
      text: "Loading...",
      block: %Block{title: " Time Entries ", borders: [:all]}
    }
  end

  defp render_time_entries(%{time_entries: []}) do
    %Paragraph{
      text: "No time entries found.",
      block: %Block{title: " Time Entries ", borders: [:all]}
    }
  end

  defp render_time_entries(%{time_entries: entries}) do
    items =
      entries
      |> Enum.take(50)
      |> Enum.map(fn e ->
        date = e["date_at"] || "?"
        minutes = format_minutes(e["minutes"] || 0)
        note = e["note"] || "(no note)"
        project = e["project_name"] || "No project"
        "#{date}  #{minutes}  #{project}  #{note}"
      end)

    %List{
      items: items,
      block: %Block{title: " Time Entries (#{length(entries)}) ", borders: [:all]}
    }
  end

  defp placeholder(title) do
    %Paragraph{
      text: "#{title} — coming soon",
      block: %Block{title: " #{title} ", borders: [:all]}
    }
  end

  # --- Events ---

  @impl true
  def handle_event(%ExRatatui.Event.Key{code: "q"}, state), do: {:stop, state}

  def handle_event(%ExRatatui.Event.Key{code: "tab"}, state) do
    {:noreply, %{state | tab: rem(state.tab + 1, length(@tabs))}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "right"}, state) do
    {:noreply, %{state | tab: rem(state.tab + 1, length(@tabs))}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "left"}, state) do
    {:noreply, %{state | tab: rem(state.tab - 1 + length(@tabs), length(@tabs))}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "r"}, state) do
    send(self(), :fetch_data)
    {:noreply, %{state | loading: true}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "t"}, %{client: nil} = state) do
    {:noreply, %{state | error: "No API client — check config"}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "t"}, state) do
    case state.tracker do
      nil ->
        # Nothing tracking — user would need to select an entry first
        {:noreply, %{state | error: "Select a time entry first (coming soon)"}}

      %{"tracking_time_entry" => entry} ->
        Task.start(fn ->
          Tracker.stop(state.client, entry["id"])
          send(self(), :fetch_data)
        end)

        {:noreply, state}
    end
  end

  def handle_event(_event, state), do: {:noreply, state}

  # --- Async data fetching ---

  @impl true
  def handle_info(:fetch_data, %{client: nil} = state) do
    {:noreply, %{state | loading: false}}
  end

  def handle_info(:fetch_data, state) do
    pid = self()

    Task.start(fn ->
      tracker = fetch_tracker(state.client)
      time_entries = fetch_time_entries(state.client)
      send(pid, {:data, tracker, time_entries})
    end)

    {:noreply, state}
  end

  def handle_info({:data, tracker, time_entries}, state) do
    {:noreply,
     %{state | tracker: tracker, time_entries: time_entries, loading: false, error: nil}}
  end

  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, @refresh_interval)
    send(self(), :fetch_data)
    {:noreply, %{state | tick: state.tick + 1}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  # --- API helpers ---

  defp fetch_tracker(client) do
    case Tracker.get(client) do
      {:ok, %{status: 200, body: body}} -> body
      _ -> nil
    end
  end

  defp fetch_time_entries(client) do
    today = Date.to_string(Date.utc_today())

    case TimeEntries.list(client, at: today) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        Enum.map(body, fn %{"time_entry" => e} -> e end)

      _ ->
        []
    end
  end

  # --- Helpers ---

  defp format_minutes(nil), do: "0:00"

  defp format_minutes(minutes) do
    h = div(minutes, 60)
    m = rem(minutes, 60)
    "#{h}:#{String.pad_leading(Integer.to_string(m), 2, "0")}"
  end
end
