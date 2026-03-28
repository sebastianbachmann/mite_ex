defmodule ElixirMite.TUI.Views.Customers do
  @moduledoc "Customer management view."

  alias ExRatatui.Widgets.{Block, Paragraph}

  def widget(_state) do
    %Paragraph{
      text: "Customers — coming soon",
      block: %Block{title: " Customers ", borders: [:all]}
    }
  end
end
