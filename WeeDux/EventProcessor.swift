//
//  Created by Kevin O'Neill on 11/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

public typealias EventProcessor<Environment, State, Event> = (State, Event) -> (State, Command<Environment, Event>)
public typealias Reducer<State, Event> = (State, Event) -> State

func merge<Environment, State, Event>(processors: [EventProcessor<Environment, State, Event>]) -> EventProcessor<Environment, State, Event> {
  return { (state: State, event: Event) in
    let reduced: (State, [Command<Environment, Event>]) = processors.reduce((state, []), { current, processor in
      let (state, commands) = current
      let (updated, command) = processor(state, event)
      return (updated, commands + [command])
    })

    return (reduced.0, .batch(reduced.1))
  }
}

public func merge<Environment, State, Event>(
  _ first: @escaping EventProcessor<Environment, State, Event>,
  _ second: @escaping EventProcessor<Environment, State, Event>,
  _ rest: EventProcessor<Environment, State, Event>...
) -> EventProcessor<Environment, State, Event> {
  return merge(processors: [first, second] + rest)
}

public func <> <Environment, State, Event>(
  _ first: @escaping EventProcessor<Environment, State, Event>,
  _ second: @escaping EventProcessor<Environment, State, Event>
) -> EventProcessor<Environment, State, Event> {
  return merge(processors: [first, second])
}

public func from<Environment, State, Event>(reducer: @escaping Reducer<State, Event>) -> EventProcessor<Environment, State, Event> {
  return { state, event in (reducer(state, event), .none) }
}

public func from<Environment, State, Event>(_ first: @escaping Reducer<State, Event>, _ rest: Reducer<State, Event>...) -> EventProcessor<Environment, State, Event> {
  return merge(processors: ([first] + rest).map { from(reducer: $0) })
}
