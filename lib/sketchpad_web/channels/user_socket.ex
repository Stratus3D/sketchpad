defmodule SketchpadWeb.UserSocket do
  use Phoenix.Socket

  ## Channels

  # channel "pad:*", SketchpadWeb.RoomChannel
  channel "pad:lobby", SketchpadWeb.PadChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "token123", token, max_age: 1209600) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}
      {:error, _reason} -> :error
    end
  end

  def id(_socket), do: nil
end
