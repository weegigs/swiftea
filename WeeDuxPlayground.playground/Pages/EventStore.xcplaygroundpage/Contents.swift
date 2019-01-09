//: [Observables](Observables)

import WeeDux

let store = SimpleEventStore<String, Int>("0", reducer: { state, event in return "\(state)-\(event)"})


store.subscribe {
  print("new state: \($0)")
}

//: Event stores can be published to

store.publish(sync: 1)
store.publish(sync: 42)

//: We can also listen to the events that have been published
//: unlike subscribing listening doesn't provide a current value
//: when you attach to it
store.listen {
  print("event processed: \($0)")
}

store.publish(sync: 18)
store.publish(sync: 31)

//: Next up: [Events](Events)
