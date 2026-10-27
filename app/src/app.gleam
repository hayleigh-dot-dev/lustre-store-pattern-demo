// IMPORTS ---------------------------------------------------------------------

import gleam/dynamic/decode
import gleam/int
import gleam/json
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init:, update:, view:)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(time: Int, count: Int)
}

fn init(_) -> #(Model, Effect(Message)) {
  let model = Model(time: 0, count: 0)

  let effect =
    effect.batch([
      subscribe_to_time(),
      subscribe_to_count(),
    ])

  #(model, effect)
}

fn subscribe_to_time() -> Effect(Message) {
  effect.subscribe("time", {
    decode.int
    |> decode.map(StoreProvidedTime)
  })
}

fn subscribe_to_count() -> Effect(Message) {
  effect.subscribe("count", {
    decode.int
    |> decode.map(StoreProvidedCount)
  })
}

// UPDATE ----------------------------------------------------------------------

type Message {
  StoreProvidedCount(value: Int)
  StoreProvidedTime(time: Int)
  UserClickedIncrement
  UserClickedDecrement
}

fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    StoreProvidedCount(value:) -> #(Model(..model, count: value), effect.none())
    StoreProvidedTime(time:) -> #(Model(..model, time:), effect.none())
    UserClickedIncrement -> #(model, event.emit("increment", json.null()))
    UserClickedDecrement -> #(model, event.emit("decrement", json.null()))
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Message) {
  html.div([], [
    html.p([], [
      html.text("The server time is: " <> int.to_string(model.time)),
    ]),

    html.div([], [
      html.button([event.on_click(UserClickedDecrement)], [html.text("-")]),
      html.button([event.on_click(UserClickedIncrement)], [html.text("+")]),
      html.p([], [
        html.text("The server count is: " <> int.to_string(model.count)),
      ]),
    ]),
  ])
}
