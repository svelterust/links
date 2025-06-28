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



  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> "unknown"
    end
  end

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()

    # Convert NaiveDateTime to DateTime if needed
    datetime =
      case datetime do
        %DateTime{} = dt -> dt
        %NaiveDateTime{} = ndt -> DateTime.from_naive!(ndt, "Etc/UTC")
      end

    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end
