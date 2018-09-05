defmodule SketchpadWeb.PadChannel do
  use SketchpadWeb, :channel

  def topic(pad_id) do
    "pad:#{pad_id}"
  end

  def broadcast_stroke_from(from, pad_id, user_id, stroke) do
    SketchpadWeb.Endpoint.broadcast_from(from, topic(pad_id), "stroke", %{
      user_id: user_id,
      stroke: stroke
    })
  end

  def join("pad:" <> pad_id, _params, socket) do
    socket =
      socket
      |> assign(:pad_id, pad_id)
      |> assign(:count, 0)

    {:ok, assign(socket, :pad_id, pad_id)}
  end

  def handle_in("stroke", data, %{assigns: %{pad_id: pad_id, user_id: user_id}} = socket) do
    broadcast_stroke_from(self(), pad_id, user_id, data)

    {:noreply, socket}
  end

  def handle_in("clear", _, %{assigns: %{pad_id: pad_id}} = socket) do
    broadcast_clear(pad_id)
    {:reply, :ok, socket}
  end

  def handle_in("new_message", %{"body" => body}, socket) do
    broadcast!(socket, "new_message", %{
      user_id: socket.assigns.user_id,
      body: body
    })
    {:reply, {:ok, %{body: body}}, socket}
  end

  def broadcast_clear(pad_id) do
    pad_id
    |> topic()
    |> SketchpadWeb.Endpoint.broadcast!("clear", %{})
  end

  def handle_info(:count, socket) do
    new_count = socket.assigns.count + 1
    push(socket, "tick", %{value: new_count})
    {:noreply, assign(socket, :count, new_count)}
  end
end
