defmodule LinksWeb.CommentsLive do
  use LinksWeb, :live_view

  alias Links.Posts

  def mount(%{"id" => post_id}, _session, socket) do
    post = Posts.get_post_with_comments!(post_id)
    changeset = Posts.change_comment(%Posts.Comment{})

    {:ok,
     socket
     |> assign(:post, post)
     |> assign(:changeset, changeset)
     |> assign(:comments, post.comments)
     |> assign(:page_title, post.title)}
  end

  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset =
      %Posts.Comment{}
      |> Posts.change_comment(comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    comment_params = Map.put(comment_params, "link_id", socket.assigns.post.id)

    case Posts.create_comment(comment_params) do
      {:ok, _comment} ->
        # Reload the post with updated comments
        post = Posts.get_post_with_comments!(socket.assigns.post.id)
        changeset = Posts.change_comment(%Posts.Comment{})

        {:noreply,
         socket
         |> assign(:post, post)
         |> assign(:comments, post.comments)
         |> assign(:changeset, changeset)
         |> put_flash(:info, "Comment posted successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
