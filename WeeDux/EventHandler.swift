//
//  Created by Kevin O'Neill on 11/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

public typealias EventHandler<Environment, State, Event> = (State, Event) -> (State, Command<Environment, Event>)

private func merge<Environment, State, Event>(_ handlers: [EventHandler<Environment, State, Event>]) -> EventHandler<Environment, State, Event> {
  return { (state: State, event: Event) in
    let reduced: (State, [Command<Environment, Event>]) = handlers.reduce((state, []), { current, processor in
      let (state, commands) = current
      let (updated, command) = processor(state, event)
      return (updated, commands + [command])
    })

    return (reduced.0, .batch(reduced.1))
  }
}

public func <> <Environment, State, Event>(
  _ first: @escaping EventHandler<Environment, State, Event>,
  _ second: @escaping EventHandler<Environment, State, Event>
) -> EventHandler<Environment, State, Event> {
  return merge([first, second])
}

public func handler<Environment, State, Event>(_ reducer: @escaping Reducer<State, Event>) -> EventHandler<Environment, State, Event> {
  return { state, event in (reducer(state, event), .none) }
}

public func handler<Environment, State, Value, Event>(
  _ path: WritableKeyPath<State, Value>,
  _ handlers: EventHandler<Environment, Value, Event>...
) -> EventHandler<Environment, State, Event> {
  let handler = merge(handlers)
  return { state, event in
    let (update, commands) = handler(state[keyPath: path], event)
    var updated = state
    updated[keyPath: path] = update

    return (updated, commands)
  }
}
