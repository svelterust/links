defmodule LinksWeb.CommentsLive do
  use LinksWeb, :live_view

  alias Links.Posts

  def mount(%{"id" => post_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Links.PubSub, "posts")
      Phoenix.PubSub.subscribe(Links.PubSub, "comments:#{post_id}")
    end

    post = Posts.get_post_with_comments!(post_id)
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    # Initialize changeset with link_id and author if user is logged in
    initial_attrs = %{"link_id" => post_id}

    initial_attrs =
      if current_user,
        do: Map.put(initial_attrs, "author", current_user.username),
        else: initial_attrs

    changeset = Posts.change_comment(%Posts.Comment{}, initial_attrs)
    user_vote = get_user_vote_for_post(current_user, post.id)

    {:ok,
     socket
     |> assign(:post, post)
     |> assign(:changeset, changeset)
     |> assign(:comments, post.comments)
     |> assign(:current_user, current_user)
     |> assign(:user_vote, user_vote)
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
    current_user = socket.assigns.current_user

    # Ensure we have the required fields
    comment_params =
      comment_params
      |> Map.put("link_id", socket.assigns.post.id)
      |> Map.put("author", (current_user && current_user.username) || comment_params["author"])

    case Posts.create_comment(comment_params) do
      {:ok, _comment} ->
        # Reset form with clean changeset
        initial_attrs = %{"link_id" => socket.assigns.post.id}

        initial_attrs =
          if current_user,
            do: Map.put(initial_attrs, "author", current_user.username),
            else: initial_attrs

        changeset = Posts.change_comment(%Posts.Comment{}, initial_attrs)

        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> put_flash(:info, "Comment posted successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("vote", %{"post_id" => post_id, "type" => vote_type}, socket) do
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    case current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to vote")}

      user ->
        post = Posts.get_post!(post_id)

        case Posts.vote_on_post(user, post, vote_type) do
          {:ok, updated_post} ->
            # Broadcast the update to all connected clients
            Phoenix.PubSub.broadcast(Links.PubSub, "posts", {:post_updated, updated_post})

            {:noreply, socket}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Unable to vote on this post")}
        end
    end
  end

  def handle_info({:post_updated, updated_post}, socket) do
    if updated_post.id == socket.assigns.post.id do
      # Update the post when it's the same post (for comment count updates)
      current_user = socket.assigns.current_scope && socket.assigns.current_scope.user
      user_vote = get_user_vote_for_post(current_user, updated_post.id)

      # Also reload comments to get the latest
      post_with_comments = Posts.get_post_with_comments!(updated_post.id)

      {:noreply,
       socket
       |> assign(:post, post_with_comments)
       |> assign(:comments, post_with_comments.comments)
       |> assign(:user_vote, user_vote)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:new_comment, _comment}, socket) do
    # Reload the post with updated comments when a new comment is added
    post = Posts.get_post_with_comments!(socket.assigns.post.id)

    {:noreply,
     socket
     |> assign(:post, post)
     |> assign(:comments, post.comments)}
  end

  # Private functions
  defp get_user_vote_for_post(user, post_id) do
    Posts.get_user_vote_for_post(user.id, post_id)
  end
end
