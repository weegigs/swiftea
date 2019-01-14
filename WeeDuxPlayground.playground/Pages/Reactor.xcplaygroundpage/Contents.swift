//: [Observables](Observables)

import WeeDux

let reactor = Reactor(state: "", environment: [:], handler: { (state: String, event: String) -> (String, Command<Any, String>) in
  if state.isEmpty {
    return (event, .none)
  }

  return ("\(state)-\(event)", .none)
})

//:Events can be dispatched to a reactor to update its state
reactor.dispatch("hello")
reactor.dispatch("world")


//: You can read a reactors state using the read function
reactor.read()


//: But you're better off subscribing as a `Reactor` is also an `Observalbe`

var current: String!
let subscription = reactor.subscribe { state in
  current = state
}

reactor.read() == current
current

reactor.dispatch("my name is kevin")

reactor.read() == current
current

//: Note the above can theortically fail as current is updated on a distinct queue.
// `read()` will always be correct 

subscription.unsubscribe()

//: Next up: [Events](Events)
