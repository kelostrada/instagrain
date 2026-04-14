defmodule InstagrainWeb.EmojiPicker do
  @moduledoc """
  Reusable emoji picker component.

  Renders a trigger button (smiley icon) that opens a popup with categorized
  emojis. When an emoji is clicked, it is inserted at the cursor position
  of the target textarea/input.

  Uses a JS hook for instant interaction (no server round-trips).

  ## Usage

      <.emoji_picker id="my-picker" target_id="my_textarea_id" />
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :target_id, :string, required: true
  attr :class, :string, default: nil

  def emoji_picker(assigns) do
    assigns = assign(assigns, :categories, categories())

    ~H"""
    <div class={["relative", @class]} id={@id} phx-hook="EmojiPicker" data-target={@target_id}>
      <button
        type="button"
        data-emoji-trigger
        class="cursor-pointer"
        aria-label="Add emoji"
      >
        <.icon name="hero-face-smile" class="h-6 w-6 text-neutral-500 hover:text-neutral-700 transition-colors" />
      </button>

      <%!-- Popup is fixed-positioned by JS to escape overflow containers --%>
      <div
        data-emoji-popup
        class="hidden fixed w-72"
        style="z-index: 200; filter: drop-shadow(0 2px 8px rgba(0,0,0,0.15)) drop-shadow(0 0 1px rgba(0,0,0,0.1));"
      >
        <div class="max-h-64 overflow-y-auto bg-white rounded-xl p-3">
          <div :for={{name, emojis} <- @categories}>
            <p class="font-bold text-sm mb-2"><%= name %></p>
            <div class="flex flex-wrap gap-0.5 mb-3">
              <button
                :for={emoji <- emojis}
                type="button"
                data-emoji={emoji}
                class="text-2xl w-9 h-9 flex items-center justify-center hover:bg-neutral-100 rounded cursor-pointer"
              >
                <%= emoji %>
              </button>
            </div>
          </div>
        </div>
        <%!-- Speech bubble triangle — overlaps body by 1px so they merge --%>
        <div
          class="ml-2.5 -mt-px"
          style="width: 0; height: 0; border-left: 8px solid transparent; border-right: 8px solid transparent; border-top: 8px solid white;"
        />
      </div>
    </div>
    """
  end

  defp icon(assigns) do
    InstagrainWeb.CoreComponents.icon(assigns)
  end

  defp categories do
    [
      {"Most popular",
       ~w(😂 😮 😍 🥹 👏 🔥 🎉 💯 ❤️ 🤣 🥰 😘 😭 😊)},
      {"Smileys & Emotion",
       ~w(😀 😃 😄 😁 😆 😅 🙂 🙃 😉 😇 🤩 😗 😚 😙 🥲 😋 😛 😜 🤪 😝 🤑 🤗 🤭 🤫 🤔 🤐 🤨 😐 😑 😶 😏 😒 🙄 😬 😌 😔 😪 🤤 😴 😷 🤒 🤕 🤢 🤮 🥵 🥶 🥴 😵 🤯 🤠 🥳 🥸 😎 🤓 🧐 😕 😟 😯 😲 😳 🥺 😦 😧 😨 😰 😥 😢 😱 😖 😣 😞 😓 😩 😫 🥱 😤 😡 😠 🤬 😈 👿 💀 💩 🤡 👻 👽 🤖)},
      {"Gestures",
       ~w(👋 🤚 🖐 ✋ 🖖 👌 🤌 🤏 ✌️ 🤞 🤟 🤘 🤙 👈 👉 👆 👇 ☝️ 👍 👎 ✊ 👊 🤛 🤜 👏 🙌 👐 🤲 🤝 🙏 💪)},
      {"Hearts",
       ~w(❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎 💔 ❣️ 💕 💞 💓 💗 💖 💘 💝)},
      {"Animals & Nature",
       ~w(🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🙈 🙉 🙊 🐔 🐧 🐦 🦆 🦅 🦉 🐺 🐴 🦄 🐝 🦋 🐌 🐞 🐢 🐍 🐙 🐬 🐳 🦈 🐘 🦒 🌸 🌹 🌺 🌻 🌼 🌷 🌱 🌲 🌳 🍀 🍁 🍂 🍃)},
      {"Food & Drink",
       ~w(🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓 🍒 🍑 🥭 🍍 🥝 🍅 🥑 🍔 🍟 🍕 🌮 🍣 🍦 🍩 🍪 🎂 🍫 🍿 ☕ 🍵 🍺 🍷 🥤 🧋)},
      {"Activities",
       ~w(⚽ 🏀 🏈 ⚾ 🎾 🏐 🎱 🏓 🏆 🥇 🎪 🎨 🎬 🎤 🎧 🎹 🎸 🎲 🎮 🎯)},
      {"Travel & Places",
       ~w(🚗 🚕 🏎 🚀 🛸 ✈️ 🚢 🏠 🏰 🗼 🗽 🎡 🎢 🌋 🏔 🏖 🌅 🌄 🌈 🌊)},
      {"Objects & Symbols",
       ~w(💡 📱 💻 📷 🔑 💰 💎 📚 ✏️ 🔔 🎁 🎈 🧸 ✨ ⭐ 🌟 💫 ☀️ 🌙 💧 ⚡ 🎵 🎶 💬 💭 🏳️ 🏴 🚩)}
    ]
  end
end
