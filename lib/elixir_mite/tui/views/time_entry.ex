defmodule ElixirMite.TUI.Views.TimeEntry do
  @moduledoc "Time entry list and create/edit view."

  alias ExRatatui.Widgets.{Block, Paragraph}

  def widget(_state) do
    %Paragraph{
      text: "Time Entries — coming soon",
      block: %Block{title: " Time Entries ", borders: [:all]}
    }
  end
end
