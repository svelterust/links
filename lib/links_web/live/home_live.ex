defmodule LinksWeb.HomeLive do
  use LinksWeb, :live_view

  alias Links.Posts

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Links.PubSub, "posts")
    end

    posts = Posts.list_posts_by_points()
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user
    user_votes = get_user_votes_for_posts(current_user, posts)

    {:ok,
     socket
     |> assign(:posts, posts)
     |> assign(:current_user, current_user)
     |> assign(:user_votes, user_votes)
     |> assign(:page_title, "Home")}
  end

  def handle_event("delete_post", %{"post_id" => post_id}, socket) do
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    case current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to delete posts")}

      user ->
        post = Posts.get_post!(post_id)

        if post.user_id == user.id do
          case Posts.delete_post(post) do
            {:ok, _deleted_post} ->
              {:noreply, put_flash(socket, :info, "Post deleted successfully")}

            {:error, _changeset} ->
              {:noreply, put_flash(socket, :error, "Unable to delete this post")}
          end
        else
          {:noreply, put_flash(socket, :error, "You can only delete your own posts")}
        end
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
    # Update the posts list with the new post data (maintain current order)
    updated_posts =
      socket.assigns.posts
      |> Enum.map(fn post ->
        if post.id == updated_post.id, do: updated_post, else: post
      end)

    # Update user votes if current user voted on this post
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    updated_user_votes =
      case current_user do
        nil ->
          socket.assigns.user_votes

        user ->
          new_vote = Posts.get_user_vote_for_post(user.id, updated_post.id)
          Map.put(socket.assigns.user_votes, updated_post.id, new_vote)
      end

    {:noreply,
     socket
     |> assign(:posts, updated_posts)
     |> assign(:user_votes, updated_user_votes)}
  end

  def handle_info({:new_post, new_post}, socket) do
    # Add new post to the top of the list
    updated_posts = [new_post | socket.assigns.posts]
    
    # Get user vote for the new post if user is logged in
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user
    
    updated_user_votes =
      case current_user do
        nil ->
          socket.assigns.user_votes
        
        user ->
          vote = Posts.get_user_vote_for_post(user.id, new_post.id)
          Map.put(socket.assigns.user_votes, new_post.id, vote)
      end

    {:noreply,
     socket
     |> assign(:posts, updated_posts)
     |> assign(:user_votes, updated_user_votes)}
  end

  def handle_info({:post_deleted, deleted_post}, socket) do
    # Remove the deleted post from the list
    updated_posts = Enum.reject(socket.assigns.posts, &(&1.id == deleted_post.id))
    
    # Remove the user vote for the deleted post
    updated_user_votes = Map.delete(socket.assigns.user_votes, deleted_post.id)

    {:noreply,
     socket
     |> assign(:posts, updated_posts)
     |> assign(:user_votes, updated_user_votes)}
  end

  # Private functions

  defp get_user_votes_for_posts(nil, _posts), do: %{}

  defp get_user_votes_for_posts(user, posts) do
    post_ids = Enum.map(posts, & &1.id)

    Posts.get_user_votes_for_posts(user.id, post_ids)
    |> Enum.into(%{}, fn vote -> {vote.post_id, vote} end)
  end
end
