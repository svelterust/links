defmodule LinksWeb.CommentsLive do
  use LinksWeb, :live_view

  alias Links.Posts

  def mount(%{"id" => post_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Links.PubSub, "posts")
    end

    post = Posts.get_post_with_comments!(post_id)
    changeset = Posts.change_comment(%Posts.Comment{})
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user
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
      # Update the post and user vote
      current_user = socket.assigns.current_scope && socket.assigns.current_scope.user
      user_vote = get_user_vote_for_post(current_user, updated_post.id)
      
      {:noreply, socket 
       |> assign(:post, updated_post)
       |> assign(:user_vote, user_vote)}
    else
      {:noreply, socket}
    end
  end

  # Private functions

  defp get_user_vote_for_post(nil, _post_id), do: nil
  
  defp get_user_vote_for_post(user, post_id) do
    Posts.get_user_vote_for_post(user.id, post_id)
  end
end
