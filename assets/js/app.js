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
    SubmitOnEnter: {
      mounted() {
        this.el.addEventListener("keydown", e => {
          if (!e.shiftKey && e.key == "Enter" && this.el.value.trim() != "") {
            this.el.form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
            e.preventDefault();
          }
        })
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
