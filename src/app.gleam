import app/store
import ewe
import filepath
import gleam/erlang/application
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/option
import gleam/result
import lustre
import lustre/server_component

pub fn main() {
  // Start a single instance of the store that is shared across all clients.
  // Everyone should see the same count and server time.
  let assert Ok(store) = lustre.start_server_component(store.new(), Nil)

  let assert Ok(_) =
    ewe.new(handler: handle_request(_, store))
    |> ewe.listening(on: 3000)
    |> ewe.start

  process.sleep_forever()
}

fn handle_request(
  request: request.Request(ewe.Connection),
  store: lustre.Runtime(store.Message),
) -> response.Response(ewe.Body) {
  case request.path_segments(request) {
    // Serve the server component client runtime. This registers the 
    // `<lustre-server-component>` custom element.
    ["static", "server-component.mjs"] -> {
      let assert Ok(priv) = application.priv_directory("lustre")
      let path = filepath.join(priv, "static/lustre-server-component.mjs")

      let assert Ok(body) =
        ewe.file(request.body, path, option.None, option.None)

      response.new(200)
      |> response.set_body(body)
      |> response.set_header("content-type", "application/javascript")
    }

    // Handle websocket connections to the store.
    ["ws", "store"] ->
      ewe.websocket(
        request:,
        on_init: fn(_, selector) {
          let self = process.new_subject()
          let selector = selector |> process.select(self)

          server_component.register_subject(self)
          |> lustre.send(to: store)

          #(self, selector)
        },
        handler: fn(connection, self, message) {
          case message {
            ewe.TextFrame(text:) -> {
              let _ =
                json.parse(text, server_component.runtime_message_decoder())
                |> result.map(lustre.send(to: store, message: _))

              ewe.continue(self)
            }

            ewe.BinaryFrame(..) -> ewe.continue(self)

            ewe.UserMessage(client_message) -> {
              let json = server_component.client_message_to_json(client_message)
              let assert Ok(_) =
                ewe.send_text_frame(connection, json.to_string(json))

              ewe.continue(self)
            }
          }
        },
        on_close: fn(self) {
          server_component.deregister_subject(self)
          |> lustre.send(to: store)
        },
      )

    _ -> panic
  }
}
