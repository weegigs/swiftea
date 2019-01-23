//: [Previous](@previous)

import WeeDux

typealias MathMiddleware =  Middleware<Int, MathEvent>

func create(_ middleware: MathMiddleware...) -> Program<Any, Int, MathEvent> {
  return Program<Any, Int, MathEvent>(state: 0, environment: (), middleware: middleware, handler: math)
}

//: A simle logging function that prints the event and new state

let logging: MathMiddleware = { state, next in { event in
  next(event)
  print("processed: \(type(of: event)).\(event), state: \(state())")
  } }


let logged = create(logging)
logged.dispatch(.increment(1))
logged.dispatch(.increment(13))

//: What about recording

class Recorder<State, Event> {
  private let worker: DispatchQueue = DispatchQueue(label: "worker")
  private(set) var events: [Event] = []

  var recorder: Middleware<State, Event> {
    return { (state, next) in { event in
      self.worker.sync {
        self.events.append(event)
      }
      next(event)
    }}
  }

  private func dispatcher(_ dispatch: @escaping (Event) -> Void) -> (Event) -> Void {
    return { event in
      // use sync to keep dispatch and read in sync 
      self.worker.sync {
        dispatch(event)
        self.events.append(event)
      }
    }
  }

  func playback(to program: Program<Any, State, Event>) -> State {
    for event in events {
      program.dispatch(event)
    }

    return program.read()
  }
}

let recorder = Recorder<Int, MathEvent>()
let recorded = create(recorder.recorder)

recorded.dispatch(.increment(5))
recorded.dispatch(.decrement(2))

let playback = create(logging)
recorder.playback(to: playback)

recorded.read() == playback.read()

//: [Next](@next)
