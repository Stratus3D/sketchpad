defmodule SketchpadWeb.PadChannel do
  use SketchpadWeb, :channel

  def join("pad:" <> pad_id, _params, socket) do
    socket =
      socket
      |> assign(:pad_id, pad_id)
      |> assign(:count, 0)

    {:ok, assign(socket, :pad_id, pad_id)}
  end

  def handle_info(:count, socket) do
    new_count = socket.assigns.count + 1
    push(socket, "tick", %{value: new_count})
    {:noreply, assign(socket, :count, new_count)}
  end
end
