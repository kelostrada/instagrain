defmodule InstagrainWeb.OgMetaPlug do
  @moduledoc """
  Serves minimal HTML with Open Graph meta tags for social media crawlers.
  Allows link previews to work without authentication.
  """
  import Plug.Conn

  @bot_agents ~w(
    facebookexternalhit Twitterbot Slackbot LinkedInBot WhatsApp
    Discordbot TelegramBot Googlebot bot crawler spider preview
  )

  def init(opts), do: opts

  def call(conn, _opts) do
    if bot_request?(conn) do
      case serve_og(conn) do
        {:ok, conn} -> conn |> halt()
        :pass -> conn
      end
    else
      conn
    end
  end

  defp bot_request?(conn) do
    ua = get_req_header(conn, "user-agent") |> List.first() || ""
    Enum.any?(@bot_agents, &String.contains?(String.downcase(ua), String.downcase(&1)))
  end

  defp serve_og(%{request_path: "/p/" <> id} = conn) do
    with {id, _} <- Integer.parse(id),
         post when not is_nil(post) <- safe_get_post(id) do
      base_url = InstagrainWeb.Endpoint.url()

      {image, image_type} =
        case post.resources do
          [resource | _] -> InstagrainWeb.Media.resource_og(resource)
          _ -> {nil, nil}
        end

      caption = post.caption || ""

      desc =
        if String.length(caption) > 200, do: String.slice(caption, 0, 197) <> "...", else: caption

      title = "#{post.user.full_name || post.user.username} on Instagrain"

      {:ok,
       send_og_html(conn, title, desc, image, image_type, "#{base_url}/p/#{post.id}", "article")}
    else
      _ -> :pass
    end
  end

  defp serve_og(%{request_path: "/" <> username} = conn) when username != "" do
    # Skip paths with slashes (not a username route)
    if String.contains?(username, "/") do
      :pass
    else
      case safe_get_profile(username) do
        nil ->
          :pass

        profile ->
          base_url = InstagrainWeb.Endpoint.url()
          {image, image_type} = InstagrainWeb.Media.avatar_og(profile)

          desc = profile.description || "#{profile.full_name || profile.username}'s profile"
          title = "#{profile.full_name || profile.username} (@#{profile.username})"

          {:ok,
           send_og_html(
             conn,
             title,
             desc,
             image,
             image_type,
             "#{base_url}/#{profile.username}",
             "profile"
           )}
      end
    end
  end

  defp serve_og(_conn), do: :pass

  defp safe_get_post(id) do
    Instagrain.Repo.get(Instagrain.Feed.Post, id)
    |> Instagrain.Repo.preload([:user, :resources])
  rescue
    _ -> nil
  end

  defp safe_get_profile(username) do
    Instagrain.Profiles.get_profile(username)
  rescue
    _ -> nil
  end

  defp send_og_html(conn, title, description, image, image_type, url, og_type) do
    image_tags =
      if image do
        type_tag =
          if image_type,
            do: ~s(<meta property="og:image:type" content="#{image_type}" />),
            else: ""

        """
        <meta property="og:image" content="#{image}" />
        <meta property="og:image:secure_url" content="#{image}" />
        <meta property="og:image:alt" content="#{escape(title)}" />
        #{type_tag}
        <meta name="twitter:image" content="#{image}" />
        <meta name="twitter:image:alt" content="#{escape(title)}" />
        """
      else
        ""
      end

    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta property="og:site_name" content="Instagrain" />
      <meta property="og:type" content="#{og_type}" />
      <meta property="og:title" content="#{escape(title)}" />
      <meta property="og:description" content="#{escape(description)}" />
      #{image_tags}
      <meta property="og:url" content="#{url}" />
      <meta name="twitter:card" content="#{if image, do: "summary_large_image", else: "summary"}" />
      <meta name="twitter:title" content="#{escape(title)}" />
      <meta name="twitter:description" content="#{escape(description)}" />
      <title>#{escape(title)}</title>
    </head>
    <body></body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  defp escape(nil), do: ""

  defp escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
