defmodule LinksWeb.PostNewLive do
  use LinksWeb, :live_view

  alias Links.Posts
  alias Links.Posts.Post

  def mount(_params, _session, socket) do
    changeset = Posts.change_post(%Post{})
    {:ok, socket |> assign(:form, to_form(changeset)) |> assign(:page_title, "New Post")}
  end

  def handle_event("validate_post", %{"post" => post_params}, socket) do
    changeset =
      %Post{}
      |> Posts.change_post(post_params)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("submit_post", %{"post" => %{"url" => url}}, socket) do
    case Posts.create_post_with_title(url, socket.assigns.current_scope.user.id) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Link submitted successfully!")
         |> redirect(to: ~p"/posts/#{post.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
