defmodule Instagrain do
  @moduledoc """
  Instagrain keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def version do
    System.get_env("VERSION") || last_git_tag() || "0.0.1"
  end

  def build_hash do
    System.get_env("VERSION_HASH") || current_git_hash() || "missing"
  end

  defp last_git_tag do
    case System.cmd("git", ["describe", "--tags", "--abbrev=0"]) do
      {tag, 0} -> String.trim(tag)
      _ -> nil
    end
  end

  defp current_git_hash do
    {hash, 0} = System.cmd("git", ["rev-parse", "HEAD"])

    hash
    |> String.trim()
    |> String.slice(0, 8)
  end
end
