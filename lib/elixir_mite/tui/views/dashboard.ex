defmodule ElixirMite.TUI.Views.Dashboard do
  @moduledoc "Dashboard view — renders today's summary and tracker status."

  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Paragraph}

  def widget(state) do
    text =
      case state[:tracker] do
        nil -> "No active tracker"
        tracker -> "Tracking: #{tracker["note"] || "untitled"}"
      end

    %Paragraph{
      text: text,
      block: %Block{
        title: " Dashboard ",
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: :green}
      }
    }
  end
end
