//: [Previous](@previous)

import WeeDux

let state = PlayObservable(0)

//: We can subscribe to a state and observe its changes. On subscription you'll rec

var current: Int = 0

state.subscribe {
  current = $0
}

//: Publish and block until complete (handy for these sort of test)
var updated = state.publish(sync: 1)

updated == current

//: Right now all we have is a simple setter, the EventSet and the State are the
//: Same type and 

//: [Next](@next)
