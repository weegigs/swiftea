//: [Previous](@previous)

import WeeDux

let observable = SimpleEventStore<String, Int>("initial", reducer: { state, event in return "\(event)"})

//: Publish and block until complete (handy for these sorts of test)
func push(_ value: Int) {
   observable.publish(sync: value)
}

//:  We subscribe to the state of an `ObservableType` to observe it's changes in
//:  value over time, we also receive the initial value
observable.subscribe {
  print($0)
}

//: Each time we push a value the current value will be printed
push(1)
push(42)

//: This will feel familiar if you've every used a reactive framework like `RxSwift`

//: Next up: [EventStore](EventStore)
