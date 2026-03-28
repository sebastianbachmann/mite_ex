defmodule ElixirMite.TUI.Views.Tracker do
  @moduledoc "Active tracker widget."

  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Paragraph}

  def widget(state) do
    {text, color} =
      case state[:tracker] do
        nil -> {"No active tracker", :dark_gray}
        t -> {"● #{t["note"] || "Tracking..."}", :green}
      end

    %Paragraph{
      text: text,
      style: %Style{fg: color},
      block: %Block{title: " Tracker ", borders: [:all]}
    }
  end
end
