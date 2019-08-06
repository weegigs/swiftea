//
//  Reducer.swift
//  WeeDux
//
//  Created by Kevin O'Neill on 14/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

public typealias ReducerFunction<State, Message> = (inout State, Message) -> Void

public struct Reducer<State, Message> {
  private var reducers: [ReducerFunction<State, Message>]

  func run(state: inout State, message: Message) {
    reducers.forEach { $0(&state, message) }
  }

  func merge(_ reducer: Reducer<State, Message>) -> Reducer<State, Message> {
    return Reducer(reducers + reducer.reducers)
  }

  func merge(_ reducer: @escaping ReducerFunction<State, Message>) -> Reducer<State, Message> {
    return Reducer(reducers + [reducer])
  }

  private init(_ reducers: [ReducerFunction<State, Message>]) {
    self.reducers = reducers
  }

  public init(_ reducer: @escaping ReducerFunction<State, Message>) {
    self.init([reducer])
  }
}

private extension Reducer {
  init(
    _ first: @escaping ReducerFunction<State, Message>,
    _ second: @escaping ReducerFunction<State, Message>
  ) {
    self.init([first, second])
  }

  init(
    _ first: @escaping ReducerFunction<State, Message>,
    _ second: Reducer<State, Message>
  ) {
    self.init([first] + second.reducers)
  }
}

public func <> <State, Message>(
  _ first: @escaping ReducerFunction<State, Message>,
  _ second: @escaping ReducerFunction<State, Message>
) -> Reducer<State, Message> { Reducer(first, second) }

public func <> <State, Message>(
  _ first: Reducer<State, Message>,
  _ second: @escaping ReducerFunction<State, Message>
) -> Reducer<State, Message> { first.merge(second) }

public func <> <State, Message>(
  _ first: @escaping ReducerFunction<State, Message>,
  _ second: Reducer<State, Message>
) -> Reducer<State, Message> { Reducer(first, second) }

public extension Reducer {
  init<Value>(path: WritableKeyPath<State, Value>, reducer: Reducer<Value, Message>) {
    self.init { state, message in
      var value = state[keyPath: path]
      reducer.run(state: &value, message: message)
      state[keyPath: path] = value
    }
  }

  init<Value>(path: WritableKeyPath<State, Value>, reducer: @escaping ReducerFunction<Value, Message>) {
    self.init(path: path, reducer: Reducer<Value, Message>(reducer))
  }
}
