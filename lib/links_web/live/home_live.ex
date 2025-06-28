defmodule LinksWeb.HomeLive do
  use LinksWeb, :live_view

  alias Links.Posts

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:posts, Posts.list_posts_by_points()) |> assign(:page_title, "Home")}
  end
end
