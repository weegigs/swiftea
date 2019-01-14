//: [Observables](Observables)

import WeeDux

let program = Program(state: "", environment: [:], handler: { (state: String, event: String) -> (String, Command<Any, String>) in
  if state.isEmpty {
    return (event, .none)
  }

  return ("\(state)-\(event)", .none)
})

//:Events can be dispatched to a program to update its state
program.dispatch("hello")
program.dispatch("world")


//: You can read a programs state using the read function
program.read()


//: But you're better off subscribing as a `program` is also an `Observalbe`

var current: String!
let subscription = program.subscribe { state in
  current = state
}

program.read() == current
current

program.dispatch("my name is kevin")

program.read() == current
current

//: Note the above can theortically fail as current is updated on a distinct queue.
// `read()` will always be correct 

subscription.unsubscribe()

//: Next up: [Events](Events)
