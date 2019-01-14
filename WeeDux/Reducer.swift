//
//  Reducer.swift
//  WeeDux
//
//  Created by Kevin O'Neill on 14/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

public typealias Reducer<State, Event> = (State, Event) -> State

public func merge<State, Event>(_ reducers: [Reducer<State, Event>]) -> Reducer<State, Event> {
  return { (state: State, event: Event) in
    reducers.reduce(state, { current, reducer in
      reducer(current, event)
    })
  }
}

public func <> <State, Event>(
  _ first: @escaping Reducer<State, Event>,
  _ second: @escaping Reducer<State, Event>
) -> Reducer<State, Event> {
  return merge([first, second])
}

public func reducer<T, V, E>(_ path: WritableKeyPath<T, V>, _ reducers: Reducer<V, E>...) -> (T, E) -> T {
  let reducer = merge(reducers)
  return { current, event in
    var state = current
    state[keyPath: path] = reducer(state[keyPath: path], event)
    return state
  }
}
