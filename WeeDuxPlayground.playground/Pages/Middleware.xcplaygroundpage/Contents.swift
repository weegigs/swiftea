//: [Previous](@previous)

import WeeDux

/*:
 Q: Why doesn't WeeDux have "Middleware"?

 A: Becuase `func` is a synonym for "Middleware"
 */

//: Projection Middleware
func create() -> Reactor<Int, MathEvent> {
 return Reactor<Int, MathEvent>(state: 0, environment: (), handler: math)
}

/*:
 As discussed earlier, projection is the combination of the functions, `publish`, `subscribe` and  `read`

 Because we use function binding within a struct scope middleware can be used on any of the interface methods
 but it's most useful with publish.

 Let's create the classic logging Middleware
 */

//: First something to wrap a `Projection<State, EventSet>.Sink` that intecepts the publish method and prints the event and new state

func logger<Event>(_ event: Event) -> Event {
    print(event)
    return event
}

//: Now a function that wraps a dispatch function

func wrap<State, Event>(_ reactor: Reactor<State, Event>, _ f: @escaping (Event) -> Event ) -> Reactor<State, Event> {
  return Reactor(dispatch: { reactor.dispatch(f($0)) }, subscribe: reactor.subscribe, read: reactor.read)
}


let logged = wrap(create(), logger)
logged.dispatch(.increment(1))


//: What about recording

class Recorder<State, Event> {
  private(set) var events: [Event] = []

  func record(_ event: Event) -> Event {
    events.append(event)
    return event
  }

  func playback(to reactor: Reactor<State, Event>) -> State {
    for event in events {
      reactor.dispatch(event)
    }

    return reactor.read()
  }
}


let recorder = Recorder<Int, MathEvent>()
let recorded = wrap(create(), recorder.record)

recorded.dispatch(.increment(5))
recorded.dispatch(.decrement(2))

let playback = wrap(create(), logger)
recorder.playback(to: playback)

recorded.read() == playback.read()

//: [Next](@next)
