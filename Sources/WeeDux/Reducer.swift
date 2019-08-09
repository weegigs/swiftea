// MIT License
//
// Copyright (c) 2019 Kevin O'Neill
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

public func <> <State, Message>(
  _ first: Reducer<State, Message>,
  _ second: Reducer<State, Message>
) -> Reducer<State, Message> { first.merge(second) }

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
