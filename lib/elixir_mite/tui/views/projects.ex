defmodule ElixirMite.TUI.Views.Projects do
  @moduledoc "Project management view."

  alias ExRatatui.Widgets.{Block, Paragraph}

  def widget(_state) do
    %Paragraph{
      text: "Projects — coming soon",
      block: %Block{title: " Projects ", borders: [:all]}
    }
  end
end
