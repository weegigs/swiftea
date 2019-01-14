//: [Previous](@previous)

import WeeDux

let observable = TestObservable("initial")

//: Publish and block until complete (handy for these sorts of test)
func push(_ value: String) {
  observable.push(sync: value)
}

//:  We subscribe to the state of an `ObservableType` to observe it's changes in
//:  value over time, we also receive the initial value
var lastUpdate: String!
var subscription = observable.subscribe {
  lastUpdate = $0
}

lastUpdate

//: Each time we push a value the current value will be printed
push("a")
lastUpdate
observable.state


push("b")
lastUpdate
observable.state

subscription.unsubscribe()
//: This will feel familiar if you've every used a reactive framework like `RxSwift`

//: Observalbes have a couple of useful extensions

observable
  .filter { $0 != "c" }
  .subscribe {
    lastUpdate = $0
  }

push("c")

//: Here you can see that state and last update are not equal
lastUpdate
observable.state

//: Next up: [EventStore](EventStore)
