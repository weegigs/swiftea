//: [Previous](@previous)

import WeeDux

/*:
 Q: Why doesn't WeeDux have "Middleware"?

 A: Becuase `func` is a synonym for "Middleware"
 */

//: Projection Middleware
func create() -> Program<Any, Int, MathEvent> {
  return Program<Any, Int, MathEvent>(state: 0, environment: (), handler: math)
}

/*:
 As discussed earlier, projection is the combination of the functions, `publish`, `subscribe` and  `read`

 Because we use function binding within a struct scope middleware can be used on any of the interface methods
 but it's most useful with publish.

 Let's create the classic logging Middleware
 */

//: First something to wrap a `Projection<State, EventSet>.Sink` that intecepts the publish method and prints the event and new state

func logger<Event>(_ event: Event) -> Void {
    print("\(Date()): \(event)")
}

//: Now a function that wraps a dispatch function

func enhance<State, Event>(_ program: Program<Any, State, Event>, _ f: @escaping (Event) -> Event ) -> Program<Any, State, Event> {
  return Program(execute: program.execute, dispatch: { program.dispatch(f($0)) }, subscribe: program.subscribe, read: program.read)
}

func enhance<State, Event>(_ program: Program<Any, State, Event>, _ f: @escaping (Event) -> Void ) -> Program<Any, State, Event> {
  return Program(execute: program.execute, dispatch: { program.dispatch($0); f($0) }, subscribe: program.subscribe, read: program.read)
}


let logged = enhance(create(), logger)
logged.dispatch(.increment(1))
logged.dispatch(.increment(13))

//: What about recording

class Recorder<State, Event> {
  private let worker: DispatchQueue = DispatchQueue(label: "worker")
  private(set) var events: [Event] = []

  func enhance(_ program: Program<Any, State, Event>) -> Program<Any, State, Event> {
    return Program(execute: program.execute, dispatch: self.dispatcher(program.dispatch), subscribe: program.subscribe, read: program.read)
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
let recorded = recorder.enhance(create())

recorded.dispatch(.increment(5))
recorded.dispatch(.decrement(2))

let playback = enhance(create(), logger)
recorder.playback(to: playback)

recorded.read() == playback.read()

//: [Next](@next)
