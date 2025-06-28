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

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6">
      <!-- Post Header -->
      <div class="mb-8 p-6 bg-white rounded-lg border border-gray-200">
        <div class="flex items-start space-x-4">
          <div class="flex flex-col items-center space-y-1 min-w-0">
            <button class="text-gray-400 hover:text-orange-500 transition-colors">
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
            </button>
            <span class="text-lg font-bold text-gray-900">{@post.points}</span>
            <button class="text-gray-400 hover:text-orange-500 transition-colors">
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M10 17a1 1 0 01-1-1v-5H4a1 1 0 110-2h5V4a1 1 0 112 0v5h5a1 1 0 110 2h-5v5a1 1 0 01-1 1z"
                  clip-rule="evenodd"
                  transform="rotate(180 10 10)"
                >
                </path>
              </svg>
            </button>
          </div>

          <div class="flex-1 min-w-0">
            <h1 class="text-xl font-bold text-gray-900 hover:text-blue-600 transition-colors mb-2">
              <a href={@post.url} target="_blank" rel="noopener noreferrer" class="block">
                {@post.title}
                <span class="text-sm text-gray-500 ml-2">({extract_domain(@post.url)})</span>
              </a>
            </h1>

            <div class="flex items-center space-x-4 text-sm text-gray-500">
              <span>by {@post.author}</span>
              <span>{format_time_ago(@post.inserted_at)}</span>
              <span>{@post.comment_count} comments</span>
              <div class="flex space-x-2">
                <%= for tag <- @post.tags do %>
                  <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {tag}
                  </span>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Comment Form -->
      <div class="mb-8 p-6 bg-white rounded-lg border border-gray-200">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Add a comment</h2>

        <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save" class="space-y-4">
          <div>
            <.input
              field={f[:author]}
              type="text"
              label="Your name"
              placeholder="Enter your name"
              required
            />
          </div>

          <div>
            <.input
              field={f[:content]}
              type="textarea"
              label="Comment"
              placeholder="What are your thoughts?"
              rows="4"
              required
            />
          </div>

          <div class="flex justify-end">
            <.button type="submit" class="bg-orange-500 hover:bg-orange-600">
              Post Comment
            </.button>
          </div>
        </.form>
      </div>
      
    <!-- Navigation -->
      <div class="mb-6">
        <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-800 transition-colors">
          ← Back to posts
        </.link>
      </div>
      
    <!-- Comments List -->
      <div class="space-y-6">
        <h2 class="text-xl font-semibold text-gray-900">
          Discussion ({length(@comments)})
        </h2>

        <%= if Enum.empty?(@comments) do %>
          <div class="text-center py-12 text-gray-500">
            <svg
              class="w-12 h-12 mx-auto mb-4 text-gray-300"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="1.5"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              >
              </path>
            </svg>
            <p class="text-lg">No comments yet</p>
            <p class="text-sm">Be the first to start the conversation!</p>
          </div>
        <% else %>
          <%= for comment <- @comments do %>
            <article class="p-6 bg-white rounded-lg border border-gray-200">
              <div class="flex items-start space-x-3">
                <div class="flex-shrink-0">
                  <div class="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
                    <span class="text-sm font-medium text-gray-700">
                      {String.first(comment.author) |> String.upcase()}
                    </span>
                  </div>
                </div>

                <div class="flex-1 min-w-0">
                  <div class="flex items-center space-x-2 mb-2">
                    <span class="font-medium text-gray-900">{comment.author}</span>
                    <span class="text-sm text-gray-500">{format_time_ago(comment.inserted_at)}</span>
                  </div>

                  <div class="text-gray-700 whitespace-pre-wrap">
                    {comment.content}
                  </div>
                </div>
              </div>
            </article>
          <% end %>
        <% end %>
      </div>
    </div>
    """
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
