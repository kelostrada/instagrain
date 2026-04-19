// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

function showToast(message) {
  const toast = document.createElement("div");
  toast.textContent = message;
  toast.style.cssText = "position:fixed;bottom:2rem;left:50%;transform:translateX(-50%);background:#262626;color:white;padding:0.75rem 1.25rem;border-radius:0.5rem;font-size:0.875rem;z-index:100;transition:opacity 0.3s;pointer-events:none;";
  document.body.appendChild(toast);
  setTimeout(() => { toast.style.opacity = "0"; }, 2000);
  setTimeout(() => { toast.remove(); }, 2300);
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    TriggerClick: {
      mounted() {
        let clickTargetId = this.el.getAttribute('data-click-target')

        this.el.addEventListener("click", e => {
          e.preventDefault()
          document.getElementById(clickTargetId).click()
        })
      }
    },
    Resizable: {
      mounted() {
        this.el.addEventListener('input', function () {
          this.style.height = 'auto';
          this.style.height = this.scrollHeight + 'px';
        });
      },

      updated() {
        this.el.style.height = 'auto';
        this.el.style.height = this.el.scrollHeight + 'px';
      }
    },
    ScrollToBottom: {
      mounted() {
        this.el.scrollTo(0, this.el.scrollHeight);
      },

      updated() {
        const pixelsBelowBottom =
          this.el.scrollHeight - this.el.clientHeight - this.el.scrollTop;

        if (pixelsBelowBottom < this.el.clientHeight * 0.3) {
          this.el.scrollTo(0, this.el.scrollHeight);
        }
      },
    },
    CopyToClipboard: {
      mounted() {
        this.el.addEventListener("click", () => {
          const text = this.el.getAttribute("data-clipboard-text");
          navigator.clipboard.writeText(text).then(() => showToast("Link copied to clipboard."));
        });
      }
    },
    NativeShare: {
      mounted() {
        this.el.addEventListener("click", (e) => {
          e.stopPropagation();
          const url = this.el.getAttribute("data-share-url");
          const title = this.el.getAttribute("data-share-title") || "";
          if (navigator.share) {
            navigator.share({ title, url }).catch((err) => {
              if (err.name !== "AbortError") {
                navigator.clipboard.writeText(url).then(() => showToast("Link copied to clipboard."));
              }
            });
          } else {
            navigator.clipboard.writeText(url).then(() => showToast("Link copied to clipboard."));
          }
        });
      }
    },
    ImageSlider: {
      mounted() {
        this.index = 0;
        this.count = parseInt(this.el.dataset.count) || 1;
        this.track = this.el.querySelector("[data-slider-track]");
        this.prevBtn = this.el.querySelector("[data-slider-prev]");
        this.nextBtn = this.el.querySelector("[data-slider-next]");
        this.dotsContainer = this.el.querySelector("[data-slider-dots]");

        if (this.count <= 1) return;

        // Arrow buttons
        this.prevBtn?.addEventListener("click", (e) => { e.stopPropagation(); this.goTo(this.index - 1); });
        this.nextBtn?.addEventListener("click", (e) => { e.stopPropagation(); this.goTo(this.index + 1); });

        // Touch swipe
        let startX = 0, startY = 0, deltaX = 0, swiping = false;
        this.el.addEventListener("touchstart", (e) => {
          startX = e.touches[0].clientX;
          startY = e.touches[0].clientY;
          deltaX = 0;
          swiping = false;
          this.track.style.transition = "none";
        }, { passive: true });

        this.el.addEventListener("touchmove", (e) => {
          deltaX = e.touches[0].clientX - startX;
          const deltaY = e.touches[0].clientY - startY;
          if (!swiping && Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 10) {
            swiping = true;
          }
          if (swiping) {
            e.preventDefault();
            const offset = -(this.index * 100) + (deltaX / this.el.offsetWidth) * 100;
            this.track.style.transform = `translateX(${offset}%)`;
          }
        }, { passive: false });

        this.el.addEventListener("touchend", () => {
          this.track.style.transition = "transform 300ms ease-out";
          if (swiping) {
            const threshold = this.el.offsetWidth * 0.2;
            if (deltaX < -threshold && this.index < this.count - 1) {
              this.goTo(this.index + 1);
            } else if (deltaX > threshold && this.index > 0) {
              this.goTo(this.index - 1);
            } else {
              this.goTo(this.index); // snap back
            }
          }
          swiping = false;
        }, { passive: true });

        this.updateUI();
      },

      goTo(idx) {
        this.index = Math.max(0, Math.min(idx, this.count - 1));
        this.track.style.transition = "transform 300ms ease-out";
        this.track.style.transform = `translateX(${-this.index * 100}%)`;
        this.updateUI();
      },

      updateUI() {
        if (!this.prevBtn) return;
        this.prevBtn.style.display = this.index > 0 ? "flex" : "none";
        this.nextBtn.style.display = this.index < this.count - 1 ? "flex" : "none";

        if (this.dotsContainer) {
          this.dotsContainer.querySelectorAll("[data-dot-index]").forEach((dot, i) => {
            dot.className = i === this.index
              ? "w-1.5 h-1.5 rounded-full transition-colors duration-300 bg-blue-500"
              : "w-1.5 h-1.5 rounded-full transition-colors duration-300 bg-white/60";
          });
        }
      }
    },
    DoubleTapLike: {
      mounted() {
        let lastTap = 0;
        const heart = this.el.querySelector("[data-heart-overlay]");

        const isNavButton = (el) => !!el.closest("[data-slider-prev], [data-slider-next]");

        this.el.addEventListener("touchend", (e) => {
          if (isNavButton(e.target)) return;
          const now = Date.now();
          if (now - lastTap < 300) {
            e.preventDefault();
            this.doLike(heart);
          }
          lastTap = now;
        });

        // Also support double-click on desktop
        this.el.addEventListener("dblclick", (e) => {
          if (isNavButton(e.target)) return;
          e.preventDefault();
          this.doLike(heart);
        });
      },

      doLike(heart) {
        // Only like if not already liked
        if (this.el.dataset.liked !== "true") {
          const targetId = this.el.dataset.target;
          this.pushEventTo(`#${targetId}`, "like", {});
        }

        // Always show heart animation
        heart.style.transition = "none";
        heart.style.opacity = "1";
        heart.style.transform = "scale(0.5)";
        requestAnimationFrame(() => {
          heart.style.transition = "transform 0.3s ease-out, opacity 0.4s ease-in 0.6s";
          heart.style.transform = "scale(1)";
          heart.style.opacity = "0";
        });
      }
    },
    PostModalGuard: {
      mounted() {
        this.modalId = "new-post-modal";
        this.modal = document.getElementById(this.modalId);
        if (!this.modal) return;

        // Build confirmation dialog
        this.overlay = document.createElement("div");
        this.overlay.className = "fixed inset-0 z-[60] flex items-center justify-center bg-black/65 hidden";
        this.overlay.innerHTML = `
          <div class="bg-white rounded-2xl w-96 max-w-[90vw] overflow-hidden text-center">
            <div class="px-8 pt-8 pb-4">
              <h2 class="text-xl font-medium">Discard post?</h2>
              <p class="text-sm text-neutral-500 mt-2">If you leave, your edits won't be saved.</p>
            </div>
            <div class="divide-y">
              <button data-action="discard" class="w-full py-3.5 text-sm font-semibold text-red-500 cursor-pointer">Discard</button>
              <button data-action="cancel" class="w-full py-3.5 text-sm font-medium cursor-pointer">Cancel</button>
            </div>
          </div>`;
        document.body.appendChild(this.overlay);

        // Prevent clicks inside dialog from closing it
        this.overlay.querySelector(".bg-white").addEventListener("click", e => e.stopPropagation());
        this.overlay.addEventListener("click", () => this.hideConfirm());

        this.overlay.querySelector("[data-action='discard']").addEventListener("click", () => {
          this.hideConfirm();
          // Close the modal
          liveSocket.execJS(this.modal, this.modal.getAttribute("phx-remove"));
          // Reset the form component (target the component, not the parent LiveView)
          this.pushEventTo(this.el, "discard-post", {});
        });

        this.overlay.querySelector("[data-action='cancel']").addEventListener("click", () => {
          this.hideConfirm();
        });

        // Intercept close triggers in capture phase
        const intercept = (e) => {
          if (this.el.dataset.hasContent === "true") {
            e.stopPropagation();
            e.preventDefault();
            this.showConfirm();
          }
        };

        // X button
        const xBtn = this.modal.querySelector("button[aria-label='close']");
        if (xBtn) xBtn.addEventListener("click", intercept, true);

        // Overlay background click (outside modal content)
        const overlayEl = document.getElementById(`${this.modalId}-overlay`);
        const modalContainer = document.getElementById(`${this.modalId}-container`);
        if (overlayEl) {
          overlayEl.addEventListener("click", (e) => {
            if (modalContainer && !modalContainer.contains(e.target) && this.el.dataset.hasContent === "true") {
              e.stopPropagation();
              e.preventDefault();
              this.showConfirm();
            }
          }, true);
        }

        // Escape key
        const container = document.getElementById(`${this.modalId}-container`);
        if (container) {
          container.addEventListener("keydown", (e) => {
            if (e.key === "Escape" && this.el.dataset.hasContent === "true") {
              e.stopPropagation();
              e.preventDefault();
              this.showConfirm();
            }
          }, true);
        }
      },

      showConfirm() { this.overlay.classList.remove("hidden"); },
      hideConfirm() { this.overlay.classList.add("hidden"); },

      destroyed() {
        if (this.overlay) this.overlay.remove();
      }
    },
    EmojiPicker: {
      mounted() {
        const trigger = this.el.querySelector("[data-emoji-trigger]");
        const popup = this.el.querySelector("[data-emoji-popup]");
        const targetId = this.el.dataset.target;

        const positionPopup = () => {
          const rect = trigger.getBoundingClientRect();
          popup.style.left = `${rect.left}px`;
          popup.style.bottom = `${window.innerHeight - rect.top + 6}px`;
        };

        trigger.addEventListener("click", (e) => {
          e.preventDefault();
          e.stopPropagation();
          const opening = popup.classList.contains("hidden");
          popup.classList.toggle("hidden");
          if (opening) positionPopup();
        });

        document.addEventListener("click", (e) => {
          if (!this.el.contains(e.target) && !popup.contains(e.target)) {
            popup.classList.add("hidden");
          }
        });

        popup.addEventListener("click", (e) => {
          const btn = e.target.closest("[data-emoji]");
          if (!btn) return;
          const emoji = btn.dataset.emoji;
          const target = document.getElementById(targetId);
          if (!target) return;

          const start = target.selectionStart;
          const end = target.selectionEnd;
          const value = target.value;
          target.value = value.slice(0, start) + emoji + value.slice(end);
          target.selectionStart = target.selectionEnd = start + emoji.length;
          target.focus();
          target.dispatchEvent(new Event("input", { bubbles: true }));
        });
      }
    },
    AdjustmentSlider: {
      mounted() {
        this.el.addEventListener("input", () => {
          this.pushEventTo(this.el, "adjust", {
            name: this.el.getAttribute("data-name"),
            value: parseInt(this.el.value)
          });
        });
      },
      updated() {
        // Sync slider value when server updates (e.g., switching between images)
      }
    },
    SubmitOnEnter: {
      resize() {
        this.el.style.height = 'auto';
        this.el.style.height = this.el.scrollHeight + 'px';
      },
      mounted() {
        this.el.addEventListener("keydown", e => {
          if (!e.shiftKey && e.key == "Enter" && this.el.value.trim() != "") {
            this.el.form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            e.preventDefault();
          }
        })
        this.el.addEventListener("input", () => this.resize());
        this.resize();
      },
      updated() {
        this.resize();
      }
    }
  }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

window.addEventListener("phx:show-toast", (e) => showToast(e.detail.message))

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

window.addEventListener("phx:close-share-modal", () => {
  // Close desktop modal
  const modal = document.getElementById("share-modal");
  if (modal) {
    liveSocket.execJS(modal, modal.getAttribute("phx-remove"));
  }
  // Close mobile full-screen
  const mobile = document.getElementById("share-mobile");
  if (mobile) {
    mobile.style.display = "none";
  }
})

window.addEventListener("phx:focus", (e) => {
  let el = document.getElementById(e.detail.id)
  if (el) {
    el.focus();
  }
})
