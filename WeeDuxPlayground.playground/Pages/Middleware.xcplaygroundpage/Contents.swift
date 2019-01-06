//: [Previous](@previous)

import WeeDux

/*:
 Q: Why doesn't WeeDux have "Middleware"?

 A: Becuase `func` is a synonym for "Middleware"
 */

//: Projection Middleware
let projection = Projection<Int, MathEvent>(state: 0, reducer: mathReducer)

/*:
 As discussed earlier, projection is the combination of the functions, `publish`, `subscribe` and  `read`

 Because we use function binding within a struct scope middleware can be used on any of the interface methods
 but it's most useful with publish.

 Let's create the classic logging Middleware
 */

//: First something to wrap a `Projection<State, EventSet>.Publisher` that intecepts the publish method and prints the event and new state

func logger<State, EventSet>(_ recorded: @escaping Projection<State, EventSet>.Publisher) -> Projection<State, EventSet>.Publisher {
  return { event, handler in
    let log = { (state: State) in
      print("event: \(event) -> state: \(state)")
      handler(state)
    }

    recorded(event, log)
  }
}

//: Now a function that wraps a Projection logs events

func logged<State, EventSet>(_ projection: Projection<State, EventSet>) -> Projection<State, EventSet> {
  return Projection(subscribe: projection.subscribe, publish: logger(projection.publish), read: projection.read)
}

let loggedProjection = logged(Projection<Int, MathEvent>(state: 0, reducer: mathReducer))
loggedProjection.publish(sync: .increment(1))


//: What about recording

class Recorder<State, EventSet> {
  private(set) var events: [EventSet] = []

  func record(_ event: EventSet) -> Void {
    events.append(event)
  }

  func playback(_ publisher: Projection<State, EventSet>.Publisher) -> State? {
    var result: State? = nil
    for event in events {
      let semaphore = DispatchSemaphore(value: 0)
      publisher(event) { state in
        result = state
        semaphore.signal()
      }
      semaphore.wait()
    }

    return result
  }
}

func recorded<State, EventSet>(publisher: @escaping Projection<State, EventSet>.Publisher, recorder: Recorder<State, EventSet>) -> Projection<State, EventSet>.Publisher {
  return { event, handler in
    let record = { (state: State) in
      recorder.record(event)
      handler(state)
    }

    publisher(event, record)
  }
}

func recorded<State, EventSet>(projection: Projection<State, EventSet>, recorder: Recorder<State, EventSet>) -> Projection<State, EventSet> {
  return Projection(subscribe: projection.subscribe, publish: recorded(publisher: projection.publish, recorder: recorder), read: projection.read)
}

let recorder = Recorder<Int, MathEvent>()
let recordedProjection = recorded(projection: Projection<Int, MathEvent>(state: 0, reducer: mathReducer), recorder: recorder)

recordedProjection.publish(sync: .increment(5))
recordedProjection.publish(sync: .decrement(2))

let playbackProjection = logged(Projection<Int, MathEvent>(state: 0, reducer: mathReducer))
recorder.playback(playbackProjection.publish)

recordedProjection.read() == playbackProjection.read()

//: [Next](@next)
