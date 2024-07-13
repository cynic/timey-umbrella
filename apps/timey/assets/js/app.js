// import the compiled Elm app, with accompanying essential JavaScript:
import { start_elm } from './main.js'
// import the other JS files:
// import './debug.js';
// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.

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
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


const setup_channels = (channel_token, email) => elm_app => {
  console.log("Setting up channels");
  let socket = new Socket("/socket", {params: {token: channel_token}});

  // When you connect, you'll often need to authenticate the client.
  // For example, imagine you have an authentication plug, `MyAuth`,
  // which authenticates the session and assigns a `:current_user`.
  // If the current user exists you can assign the user's token in
  // the connection for use in the layout.
  //
  // In your "lib/timey/router.ex":
  //
  //     pipeline :browser do
  //       ...
  //       plug MyAuth
  //       plug :put_user_token
  //     end
  //
  //     defp put_user_token(conn, _) do
  //       if current_user = conn.assigns[:current_user] do
  //         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
  //         assign(conn, :user_token, token)
  //       else
  //         conn
  //       end
  //     end
  //
  // Now you need to pass this token to JavaScript. You can do so
  // inside a script tag in "lib/timey/templates/layout/app.html.heex":
  //
  //     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
  //
  // You will need to verify the user token in the "connect/3" function
  // in "lib/timey/channels/user_socket.ex":
  //
  //     def connect(%{"token" => token}, socket, _connect_info) do
  //       # max_age: 1209600 is equivalent to two weeks in seconds
  //       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
  //         {:ok, user_id} ->
  //           {:ok, assign(socket, :user, user_id)}
  //
  //         {:error, reason} ->
  //           :error
  //       end
  //     end
  //
  // Finally, connect to the socket:
  socket.connect()

  // Now that you are connected, you can join channels with a topic & subtopic.
  let channel = socket.channel(`tcpish:${email}`, {})
  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })
};

window.start_elm = function (flags) {
  start_elm(flags, setup_channels(flags.channel_token, flags.email))
};