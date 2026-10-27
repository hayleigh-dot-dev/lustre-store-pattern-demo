// IMPORTS ---------------------------------------------------------------------

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import lustre.{type App}
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/event

// 

pub fn new() -> App(Nil, Model, Message) {
  lustre.component(init:, update:, view:, options: [])
}

// MODEL -----------------------------------------------------------------------

pub opaque type Model {
  Model(time: Int, count: Int)
}

fn init(_) -> #(Model, Effect(Message)) {
  let model = Model(time: 0, count: 0)
  let effect =
    effect.batch([
      provide_time(model.time),
      provide_count(model.count),
      schedule_tick(),
    ])

  #(model, effect)
}

fn provide_time(time: Int) -> Effect(Message) {
  effect.provide("time", json.int(time))
}

fn provide_count(count: Int) -> Effect(Message) {
  effect.provide("count", json.int(count))
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Message {
  ClientIncrementedCount
  ClientDecrementedCount
  TimerTick
}

fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    ClientIncrementedCount -> {
      let model = Model(..model, count: model.count + 1)
      let effect = provide_count(model.count)

      #(model, effect)
    }

    ClientDecrementedCount -> {
      let model = Model(..model, count: model.count - 1)
      let effect = provide_count(model.count)

      #(model, effect)
    }

    TimerTick -> {
      let model = Model(..model, time: model.time + 1)
      let effect =
        effect.batch([
          provide_time(model.time),
          schedule_tick(),
        ])

      #(model, effect)
    }
  }
}

fn schedule_tick() -> Effect(Message) {
  use dispatch <- effect.from
  let _ =
    process.spawn(fn() {
      process.sleep(1000)
      dispatch(TimerTick)
    })

  Nil
}

// VIEW ------------------------------------------------------------------------

fn view(_) -> Element(Message) {
  component.default_slot(
    [
      event.on("increment", decode.success(ClientIncrementedCount)),
      event.on("decrement", decode.success(ClientDecrementedCount)),
    ],
    [],
  )
}
