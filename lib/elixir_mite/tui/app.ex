defmodule ElixirMite.TUI.App do
  @moduledoc """
  Main TUI application using the ExRatatui.App behaviour.
  """
  use ExRatatui.App

  alias ElixirMite.API.{Client, Customers, Tracker, TimeEntries}
  alias ElixirMite.Config.Loader
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, List, Paragraph, Popup, Tabs, TextInput}

  @tabs ["Dashboard", "Time Entries", "Projects", "Customers", "Services"]
  @refresh_interval 10_000

  # --- Mount ---

  @impl true
  def mount(_opts) do
    case Loader.load() do
      {:ok, %{"account" => %{"name" => name, "api_key" => api_key}}} ->
        client = Client.new(name, api_key)
        send(self(), :fetch_data)
        send(self(), :tick)

        {:ok, initial_state(client)}

      {:error, reason} ->
        {:ok, %{initial_state(nil) | error: "Config error: #{reason}", loading: false}}
    end
  end

  defp initial_state(client) do
    %{
      tab: 0,
      client: client,
      # dashboard
      tracker: nil,
      time_entries: [],
      # customers
      customers: [],
      customers_selected: 0,
      # :list | :new | :confirm_delete
      customers_mode: :list,
      # TextInput state ref
      customers_input: nil,
      # quick tracker — :idle | :picking_customer | :stopping
      tracker_mode: :idle,
      tracker_selected: 0,
      # shared
      error: nil,
      loading: true,
      tick: 0
    }
  end

  # --- Render ---

  @impl true
  def render(state, frame) do
    area = %Rect{x: 0, y: 0, width: frame.width, height: frame.height}

    [header, body, footer] =
      Layout.split(area, :vertical, [
        {:length, 3},
        {:min, 0},
        {:length, 1}
      ])

    tabs_widget = %Tabs{
      titles: @tabs,
      selected: state.tab,
      highlight_style: %Style{fg: :cyan, modifiers: [:bold]},
      block: %Block{title: " elixir-mite ", borders: [:all], border_type: :rounded}
    }

    content = render_tab(state, body)
    status = render_status(state)

    base = [{tabs_widget, header}, {content, body}, {status, footer}]

    if state.tracker_mode == :picking_customer do
      base ++ [{render_tracker_picker(state), body}]
    else
      base
    end
  end

  defp render_status(%{tracker_mode: :picking_customer}) do
    %Paragraph{
      text: " j/k: navigate  Enter: start tracking  Esc: cancel",
      style: %Style{fg: :green}
    }
  end

  defp render_status(%{customers_mode: :new}) do
    %Paragraph{
      text: " Enter: confirm  Esc: cancel",
      style: %Style{fg: :yellow}
    }
  end

  defp render_status(%{customers_mode: :confirm_delete}) do
    %Paragraph{
      text: " y: confirm delete  Esc: cancel",
      style: %Style{fg: :red}
    }
  end

  defp render_status(state) do
    {text, style} =
      cond do
        state.error ->
          {" Error: #{state.error}  (press any key to dismiss)", %Style{fg: :red}}

        state.loading ->
          {" Loading...", %Style{fg: :yellow}}

        state.tab == 3 ->
          {" j/k: navigate  n: new  d: delete  r: refresh  q: quit", %Style{fg: :dark_gray}}

        true ->
          {" Tab/←/→: switch tabs  r: refresh  q: quit", %Style{fg: :dark_gray}}
      end

    %Paragraph{text: text, style: style}
  end

  # --- Tracker customer picker ---

  defp render_tracker_picker(%{customers: []} = _state) do
    %Popup{
      content: %Paragraph{
        text: "No customers found.\nAdd one in the Customers tab first.",
        style: %Style{fg: :yellow}
      },
      block: %Block{
        title: " Start Timer — No Customers ",
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: :yellow}
      },
      percent_width: 55,
      percent_height: 30
    }
  end

  defp render_tracker_picker(state) do
    items =
      Enum.map(state.customers, fn c ->
        archived = if c["archived"], do: " [archived]", else: ""
        "#{c["name"]}#{archived}"
      end)

    list = %List{
      items: items,
      selected: state.tracker_selected,
      highlight_style: %Style{fg: :green, modifiers: [:bold]},
      highlight_symbol: " ▶ "
    }

    %Popup{
      content: list,
      block: %Block{
        title: " Start Timer — Pick a Customer ",
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: :green}
      },
      percent_width: 55,
      percent_height: 60
    }
  end

  # --- Tab renderers ---

  defp render_tab(%{tab: 0} = state, _area), do: render_dashboard(state)
  defp render_tab(%{tab: 1} = state, _area), do: render_time_entries(state)
  defp render_tab(%{tab: 2}, _area), do: placeholder("Projects")
  defp render_tab(%{tab: 3} = state, area), do: render_customers(state, area)
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
    %Paragraph{text: "Loading...", block: %Block{title: " Time Entries ", borders: [:all]}}
  end

  defp render_time_entries(%{time_entries: []}) do
    %Paragraph{
      text: "No time entries found.",
      block: %Block{title: " Time Entries ", borders: [:all]}
    }
  end

  defp render_time_entries(%{time_entries: entries}) do
    items =
      Enum.map(entries, fn e ->
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

  defp render_customers(%{customers_mode: :new} = state, area) do
    list = render_customers_list(state)

    form = %TextInput{
      state: state.customers_input,
      placeholder: "Customer name...",
      placeholder_style: %Style{fg: :dark_gray},
      block: %Block{
        title: " New Customer ",
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: :cyan}
      }
    }

    popup = %Popup{
      content: form,
      percent_width: 60,
      percent_height: 20
    }

    # Return list as base + popup overlay as separate widget at same area
    _ = area
    _ = list
    popup
  end

  defp render_customers(%{customers_mode: :confirm_delete} = state, _area) do
    selected = Enum.at(state.customers, state.customers_selected)
    name = if selected, do: selected["name"], else: "this customer"

    %Popup{
      content: %Paragraph{
        text:
          "Delete \"#{name}\"?\n\nThis cannot be undone.\nCustomers with projects cannot be deleted (archive instead).",
        style: %Style{fg: :white}
      },
      block: %Block{
        title: " Confirm Delete ",
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: :red}
      },
      percent_width: 55,
      percent_height: 35
    }
  end

  defp render_customers(state, _area), do: render_customers_list(state)

  defp render_customers_list(%{customers: [], loading: true}) do
    %Paragraph{text: "Loading...", block: %Block{title: " Customers ", borders: [:all]}}
  end

  defp render_customers_list(%{customers: []}) do
    %Paragraph{
      text: "No customers found.\n\nPress n to create one.",
      block: %Block{title: " Customers ", borders: [:all]}
    }
  end

  defp render_customers_list(state) do
    items =
      Enum.map(state.customers, fn c ->
        archived = if c["archived"], do: " [archived]", else: ""
        "#{c["name"]}#{archived}"
      end)

    %List{
      items: items,
      selected: state.customers_selected,
      highlight_style: %Style{fg: :cyan, modifiers: [:bold]},
      highlight_symbol: " > ",
      block: %Block{title: " Customers (#{length(state.customers)}) ", borders: [:all]}
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
  # Dismiss errors on any key
  def handle_event(_event, %{error: err} = state) when not is_nil(err) do
    {:noreply, %{state | error: nil}}
  end

  # Tracker customer picker
  def handle_event(event, %{tracker_mode: :picking_customer} = state) do
    handle_tracker_picker_event(event, state)
  end

  # New customer form — typing
  def handle_event(event, %{customers_mode: :new} = state) do
    handle_new_customer_event(event, state)
  end

  # Delete confirmation
  def handle_event(event, %{customers_mode: :confirm_delete} = state) do
    handle_confirm_delete_event(event, state)
  end

  # Global keys
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

  # t — open customer picker if no tracker running, stop if running
  def handle_event(%ExRatatui.Event.Key{code: "t"}, %{client: nil} = state) do
    {:noreply, %{state | error: "No API client — check config"}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "t"}, %{tracker: nil} = state) do
    {:noreply, %{state | tracker_mode: :picking_customer, tracker_selected: 0}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "t"}, state) do
    # Stop the running tracker
    entry_id = get_in(state.tracker, ["tracking_time_entry", "id"])

    if entry_id do
      pid = self()

      Task.start(fn ->
        case Tracker.stop(state.client, entry_id) do
          {:ok, %{status: 200}} -> send(pid, {:tracker_stopped, :ok})
          _ -> send(pid, {:tracker_stopped, {:error, "Failed to stop tracker"}})
        end
      end)
    end

    {:noreply, state}
  end

  # Customers tab — list navigation
  def handle_event(%ExRatatui.Event.Key{code: "j"}, %{tab: 3} = state) do
    max = max(0, length(state.customers) - 1)
    {:noreply, %{state | customers_selected: min(state.customers_selected + 1, max)}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "k"}, %{tab: 3} = state) do
    {:noreply, %{state | customers_selected: max(state.customers_selected - 1, 0)}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "down"}, %{tab: 3} = state) do
    max = max(0, length(state.customers) - 1)
    {:noreply, %{state | customers_selected: min(state.customers_selected + 1, max)}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "up"}, %{tab: 3} = state) do
    {:noreply, %{state | customers_selected: max(state.customers_selected - 1, 0)}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "n"}, %{tab: 3, client: client} = state)
      when not is_nil(client) do
    input = ExRatatui.text_input_new()
    {:noreply, %{state | customers_mode: :new, customers_input: input}}
  end

  def handle_event(%ExRatatui.Event.Key{code: "d"}, %{tab: 3, customers: [_ | _]} = state) do
    {:noreply, %{state | customers_mode: :confirm_delete}}
  end

  def handle_event(_event, state), do: {:noreply, state}

  # --- Tracker customer picker events ---

  defp handle_tracker_picker_event(%ExRatatui.Event.Key{code: "esc"}, state) do
    {:noreply, %{state | tracker_mode: :idle}}
  end

  defp handle_tracker_picker_event(%ExRatatui.Event.Key{code: "j"}, state) do
    max = max(0, length(state.customers) - 1)
    {:noreply, %{state | tracker_selected: min(state.tracker_selected + 1, max)}}
  end

  defp handle_tracker_picker_event(%ExRatatui.Event.Key{code: "k"}, state) do
    {:noreply, %{state | tracker_selected: max(state.tracker_selected - 1, 0)}}
  end

  defp handle_tracker_picker_event(%ExRatatui.Event.Key{code: "down"}, state) do
    max = max(0, length(state.customers) - 1)
    {:noreply, %{state | tracker_selected: min(state.tracker_selected + 1, max)}}
  end

  defp handle_tracker_picker_event(%ExRatatui.Event.Key{code: "up"}, state) do
    {:noreply, %{state | tracker_selected: max(state.tracker_selected - 1, 0)}}
  end

  defp handle_tracker_picker_event(%ExRatatui.Event.Key{code: "enter"}, %{customers: []} = state) do
    {:noreply, %{state | tracker_mode: :idle}}
  end

  defp handle_tracker_picker_event(%ExRatatui.Event.Key{code: "enter"}, state) do
    customer = Enum.at(state.customers, state.tracker_selected)
    pid = self()

    Task.start(fn ->
      # Create a time entry for that customer with an honest placeholder note
      entry_attrs = %{
        customer_id: customer["id"],
        date_at: Date.to_string(Date.utc_today()),
        note: "specify this later :)"
      }

      case TimeEntries.create(state.client, entry_attrs) do
        {:ok, %{status: 201, body: %{"time_entry" => entry}}} ->
          # Immediately start the tracker on the new entry
          case Tracker.start(state.client, entry["id"]) do
            {:ok, %{status: 200}} ->
              send(pid, {:tracker_started, :ok})

            _ ->
              send(pid, {:tracker_started, {:error, "Entry created but tracker failed to start"}})
          end

        {:ok, %{status: _, body: %{"error" => msg}}} ->
          send(pid, {:tracker_started, {:error, msg}})

        _ ->
          send(pid, {:tracker_started, {:error, "Failed to create time entry"}})
      end
    end)

    {:noreply, %{state | tracker_mode: :idle}}
  end

  defp handle_tracker_picker_event(_event, state), do: {:noreply, state}

  # --- New customer form events ---

  defp handle_new_customer_event(%ExRatatui.Event.Key{code: "esc"}, state) do
    {:noreply, %{state | customers_mode: :list, customers_input: nil}}
  end

  defp handle_new_customer_event(%ExRatatui.Event.Key{code: "enter"}, state) do
    name = ExRatatui.text_input_get_value(state.customers_input)

    if String.trim(name) == "" do
      {:noreply, %{state | error: "Customer name cannot be empty"}}
    else
      pid = self()

      Task.start(fn ->
        case Customers.create(state.client, %{name: String.trim(name)}) do
          {:ok, %{status: 201}} ->
            send(pid, {:customer_created, :ok})

          {:ok, %{status: _, body: %{"error" => msg}}} ->
            send(pid, {:customer_created, {:error, msg}})

          _ ->
            send(pid, {:customer_created, {:error, "API request failed"}})
        end
      end)

      {:noreply, %{state | customers_mode: :list, customers_input: nil, loading: true}}
    end
  end

  defp handle_new_customer_event(%ExRatatui.Event.Key{code: code}, state) do
    ExRatatui.text_input_handle_key(state.customers_input, code)
    {:noreply, state}
  end

  defp handle_new_customer_event(_event, state), do: {:noreply, state}

  # --- Delete confirmation events ---

  defp handle_confirm_delete_event(%ExRatatui.Event.Key{code: "y"}, state) do
    selected = Enum.at(state.customers, state.customers_selected)

    if selected do
      pid = self()
      id = selected["id"]

      Task.start(fn ->
        case Customers.delete(state.client, id) do
          {:ok, %{status: 200}} ->
            send(pid, {:customer_deleted, :ok})

          {:ok, %{status: _, body: %{"error" => msg}}} ->
            send(pid, {:customer_deleted, {:error, msg}})

          _ ->
            send(pid, {:customer_deleted, {:error, "API request failed"}})
        end
      end)
    end

    {:noreply, %{state | customers_mode: :list, loading: true}}
  end

  defp handle_confirm_delete_event(%ExRatatui.Event.Key{code: "esc"}, state) do
    {:noreply, %{state | customers_mode: :list}}
  end

  defp handle_confirm_delete_event(_event, state), do: {:noreply, state}

  # --- handle_info ---

  @impl true
  def handle_info(:fetch_data, %{client: nil} = state) do
    {:noreply, %{state | loading: false}}
  end

  def handle_info(:fetch_data, state) do
    pid = self()

    Task.start(fn ->
      tracker = fetch_tracker(state.client)
      time_entries = fetch_time_entries(state.client)
      customers = fetch_customers(state.client)
      send(pid, {:data, tracker, time_entries, customers})
    end)

    {:noreply, state}
  end

  def handle_info({:data, tracker, time_entries, customers}, state) do
    {:noreply,
     %{
       state
       | tracker: tracker,
         time_entries: time_entries,
         customers: customers,
         loading: false,
         error: nil
     }}
  end

  def handle_info({:customer_created, :ok}, state) do
    send(self(), :fetch_data)
    {:noreply, state}
  end

  def handle_info({:customer_created, {:error, msg}}, state) do
    {:noreply, %{state | loading: false, error: msg}}
  end

  def handle_info({:customer_deleted, :ok}, state) do
    new_selected = max(0, state.customers_selected - 1)
    send(self(), :fetch_data)
    {:noreply, %{state | customers_selected: new_selected}}
  end

  def handle_info({:customer_deleted, {:error, msg}}, state) do
    {:noreply, %{state | loading: false, error: msg}}
  end

  def handle_info({:tracker_started, :ok}, state) do
    send(self(), :fetch_data)
    {:noreply, state}
  end

  def handle_info({:tracker_started, {:error, msg}}, state) do
    {:noreply, %{state | error: msg}}
  end

  def handle_info({:tracker_stopped, :ok}, state) do
    send(self(), :fetch_data)
    {:noreply, state}
  end

  def handle_info({:tracker_stopped, {:error, msg}}, state) do
    {:noreply, %{state | error: msg}}
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
      {:ok, %{status: 200, body: %{"tracker" => tracker}}} when map_size(tracker) > 0 -> tracker
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

  defp fetch_customers(client) do
    case Customers.list(client) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        Enum.map(body, fn %{"customer" => c} -> c end)

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
