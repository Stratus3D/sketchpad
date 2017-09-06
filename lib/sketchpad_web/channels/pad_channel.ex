defmodule SketchpadWeb.PadChannel do
  use SketchpadWeb, :channel
  alias Sketchpad.Pad
  alias SketchpadWeb.Presence

  @inactive_time :timer.hours(1)

  def join("pad:" <> pad_id, _params, socket) do
    send(self(), :after_join)
    socket =
      socket
      |> assign(:pad_id, pad_id)
      |> assign(:timer_ref, schedule_shutdown())

    {:ok, %{msg: "welcome!"}, socket}
  end

  def handle_info(:inactive, socket) do
    {:stop, :shutdown, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _ref} = Presence.track(socket, socket.assigns.user_id, %{})

    for {user_id, %{strokes: strokes}} <- Pad.render(socket.assigns.pad_id) do
      for stroke <- Enum.reverse(strokes) do
        push(socket, "stroke", %{user_id: user_id, stroke: stroke})
      end
    end

    {:noreply, socket}
  end

  def handle_in(event, data, socket) do
    Process.cancel_timer(socket.assigns.timer_ref)
    socket = assign(socket, :timer_ref, schedule_shutdown())
    do_handle_in(event, data, socket)
  end

  defp do_handle_in("stroke", stroke, socket) do
    %{user_id: user_id, pad_id: pad_id} = socket.assigns
    :ok = Pad.put_stroke(pad_id, user_id, stroke, self())
    {:reply, :ok, socket}
  end

  defp do_handle_in("clear", _, socket) do
    Pad.clear(socket.assigns.pad_id)

    {:reply, :ok, socket}
  end

  defp do_handle_in("new_message", %{"body" => body}, socket) do
    broadcast!(socket, "new_message", %{
      user_id: socket.assigns.user_id,
      body: body
    })
    {:reply, :ok, socket}
  end

  defp schedule_shutdown do
    Process.send_after(self(), :inactive, @inactive_time)
  end
end
