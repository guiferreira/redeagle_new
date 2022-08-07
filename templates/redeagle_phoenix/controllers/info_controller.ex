defmodule <%= @web_namespace %>.Controller do
  use <%= @web_namespace %>, :controller

  def info(conn, _) do
    json(conn, %{slogan: "It's not a bird and it's not a plane it's a union of the best Phoenix, React and Docker"})
  end
end
