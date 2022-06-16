// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
// import "../css/app.css"

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
import { calcMarkers, goToUser, init, setAutoSpin } from "./world"

// import Alpine
import Alpine from "alpinejs"

// // Add this before your liveSocket call.
window.Alpine = Alpine
Alpine.start()

let csrfToken = document
	.querySelector("meta[name='csrf-token']")
	.getAttribute("content")

let Hooks = {}
Hooks.SetLocation = {
	DEBOUNCE_MS: 200,
	user() {
		return this.el.dataset.user
	},
	mounted() {
		clearTimeout(this.timeout)
		this.timeout = setTimeout(() => {
			this.pushMyEvent = this.pushEvent
			this.cuser = this.user()
			navigator.geolocation.getCurrentPosition(async (position) => {
				this.pushEvent = this.pushMyEvent
				this.myuser = this.cuser
				console.log("set location")
				await fetch(
					`/location?lat=${position.coords.latitude}&long=${position.coords.longitude}&temp=false&user=${this.myuser}`,
					{ method: "get" }
				)
					.then((res) => {
						return res.json()
					})
					.then((res) => {
						// console.log(res)
						this.pushEvent("update_user_location", { location: res })
					})
				setTimeout(() => goToUser(this.myuser), 1000)
			})
		}, this.DEBOUNCE_MS)
	},
}

Hooks.SetTempLocation = {
	DEBOUNCE_MS: 200,
	user() {
		return this.el.dataset.user
	},
	mounted() {
		clearTimeout(this.timeout)
		this.timeout = setTimeout(() => {
			this.pushMyEvent = this.pushEvent
			this.cuser = this.user()
			// console.log(this.cuser)
			navigator.geolocation.getCurrentPosition(async (position) => {
				this.pushEvent = this.pushMyEvent
				this.myuser = this.cuser
				// console.log(this.myuser)
				// console.log("set location")
				await fetch(
					`/location?lat=${position.coords.latitude}&long=${position.coords.longitude}&temp=true&user=${this.myuser}`,
					{ method: "get" }
				)
					.then((res) => {
						return res.json()
					})
					.then((res) => {
						// console.log(res)
						this.pushEvent("update_user_location", { location: res })
					})
				setTimeout(() => goToUser(this.myuser), 1000)
			})
		}, this.DEBOUNCE_MS)
	},
}

Hooks.ScrollBottom = {
	mounted() {
		var scrollable = document.getElementById(
			"chat-container-" + this.el.getAttributeNode("phx-value-userid").value
		)
		setTimeout(() => {
			scrollable.scrollTo(0, scrollable.scrollHeight - scrollable.clientHeight)
		}, 100)
	},
}

Hooks.UpdateMarkers = {
	updated() {
		calcMarkers()
	},
}

Hooks.WorldInitialize = {
	mounted() {
		init()
	},
}

Hooks.AutoSpin = {
	mounted() {
		window.autoSpin = this
	},
	toggle(checked) {
		setAutoSpin(checked)
	},
}

Hooks.AutoSpinStart = {
	mounted() {
		window.autoSpin = this
		// setAutoSpin(true)
	},
	toggle(checked) {
		setAutoSpin(checked)
	},
}

Hooks.MarkerGoto = {
	mounted() {
		window.markerGoto = this
	},
	goto(userid) {
		goToUser(userid)
	},
}

let liveSocket = new LiveSocket("/live", Socket, {
	params: { _csrf_token: csrfToken },
	dom: {
		onBeforeElUpdated(from, to) {
			if (from._x_dataStack) {
				window.Alpine.clone(from, to)
				window.Alpine.initTree(to)
			}
		},
	},
	hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", (info) => topbar.show())
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
