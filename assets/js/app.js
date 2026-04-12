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

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

window.addEventListener("phx:focus", (e) => {
  let el = document.getElementById(e.detail.id)
  if (el) {
    el.focus();
  }
})
