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

/**
 A `HandlerFunction` process `State` for `Message` updating `State` and returning a `Command`
 */
public typealias HandlerFunction<Environment, State, Message> = (inout State, Message) -> Command<Environment, Message>

/**
 Processes `State` for a `Message` updating `State`
 */
public typealias ReducerFunction<State, Message> = (inout State, Message) -> Void

/**
 Processes `State` for `Message` updating `State` and returning a `Command`
 */
public struct MessageHandler<Environment, State, Message> {
  
  /// A convienince method that creates a `MessageHandler` from one or more `HandlerFunction`s and returns a `Command` that
  /// batchs the commands from the `HandlerFunction`s.
  ///
  /// It can be used to create a single `MessageHandler`
  ///
  /// ```
  ///   .handler { state, message in state.append(message); return Commands.fireTheMissiles }
  /// ```
  ///
  /// or to chain a number of handlers together
  ///
  /// ```
  ///  .handler(fireMissilesRequested, cancelFileMissilesRequested)
  /// ```
  ///
  /// - Parameters:
  ///   - handlers: The `HandlerFunction`s to merge
  ///
  /// - Returns:
  ///   A `MessageHandler` that executes the supplied **handlers**
  ///
  /// - Requires:
  ///   You must pass at least one `HandlerFunction`
  ///
  public static func handler(_ handlers: HandlerFunction<Environment, State, Message>...) -> MessageHandler {
    MessageHandler(handlers: handlers)
  }

  /// A convienince method that creates a `MessageHandler` from one or more `ReducerFunction`s that always returns `Command.none`.
  ///
  /// It can be used to create a single `MessageHandler`
  ///
  /// ```
  ///   .reducer { state, message in state.append(message) }
  /// ```
  ///
  /// or to chain a number of reducers together
  ///
  /// ```
  ///  .reducer(incrementReducer, decrementReducer, multiplyReducer, divideReducer)
  /// ```
  ///
  /// - Parameters:
  ///   - reducers: The `ReducerFunction`s to merge
  ///
  /// - Returns:
  ///   A `MessageHandler` that executes the supplied **reducers**
  ///
  /// - Requires:
  ///   You must pass at least one `ReducerFunction`
  ///
  public static func reducer(_ reducers: ReducerFunction<State, Message>...) -> MessageHandler<Environment, State, Message> {
    return MessageHandler(reducers: reducers)
  }
  
  private let handlers: [HandlerFunction<Environment, State, Message>]

  private init(handlers: [HandlerFunction<Environment, State, Message>]) {
    assert(!handlers.isEmpty, "You must supply at least one HandlerFunction")
    self.handlers = handlers
  }
  
  private init(reducers: [ReducerFunction<State, Message>]) {
    assert(!reducers.isEmpty, "You must supply at least one ReducerFunction")
    self.init(handlers: { state, message in
      for reducer in reducers {
        reducer(&state, message)
      }
      
      return .none
    })
  }
  
  /// Creates a `MessageHandler` from one or more `HandlerFunction`s and returns a `Command` that
  /// batchs the commands from the supplied `HandlerFunction`s.
  ///
  /// It can be used to create a single `MessageHandler`
  ///
  /// ```
  ///   MessageHandler { state, message in state.append(message); return Commands.fireTheMissiles }
  /// ```
  ///
  /// or to chain a number of handlers together
  ///
  /// ```
  ///   MessageHandler(fireMissilesRequested, cancelFileMissilesRequested)
  /// ```
  ///
  /// - Parameters:
  ///   - handlers: The `HandlerFunction`s to merge
  ///
  /// - Returns:
  ///   A `MessageHandler` that executes the supplied **handlers**
  ///
  /// - Requires:
  ///   You must pass at least one `HandlerFunction`
  ///
  public init(handlers: HandlerFunction<Environment, State, Message>...) {
    self.init(handlers: handlers)
  }
  
  /// Creates a `MessageHandler` from one or more `ReducerFunction`s that always returns `Command.none`.
  ///
  /// It can be used to create a single `MessageHandler`
  ///
  /// ```
  ///   MessageHandler { state, message in state.append(message) }
  /// ```
  ///
  /// or to chain a number of reducers together
  ///
  /// ```
  ///   MessageHandler(incrementReducer, decrementReducer, multiplyReducer, divideReducer)
  /// ```
  ///
  /// - Parameters:
  ///   - reducers: The `ReducerFunction`s to merge
  ///
  /// - Returns:
  ///   A `MessageHandler` that executes the supplied **reducers**
  ///
  /// - Requires:
  ///   You must pass at least one `ReducerFunction`
  ///
  public init(reducers: ReducerFunction<State, Message>...) {
    self.init(reducers: reducers)
  }

  public func run(state: inout State, message: Message) -> Command<Environment, Message> {
    let commands: [Command<Environment, Message>] = handlers.reduce(into: []) { commands, handler in
      commands.append(handler(&state, message))
    }

    return .batch(commands)
  }

  public func merge(_ handler: MessageHandler<Environment, State, Message>) -> MessageHandler<Environment, State, Message> {
    return MessageHandler(handlers: handlers + handler.handlers)
  }

  public func merge(_ handler: @escaping HandlerFunction<Environment, State, Message>) -> MessageHandler<Environment, State, Message> {
    return MessageHandler(handlers: handlers + [handler])
  }

  public func merge(_ reducer: @escaping ReducerFunction<State, Message>) -> MessageHandler<Environment, State, Message> {
    return merge(MessageHandler(reducers: reducer))
  }

}

extension MessageHandler {
  private init<Value>(path: WritableKeyPath<State, Value>, handler: MessageHandler<Environment, Value, Message>) {
    self.init(handlers: { state, message in
      var value = state[keyPath: path]
      let command = handler.run(state: &value, message: message)
      state[keyPath: path] = value

      return command
    })
  }

  init<Value>(path: WritableKeyPath<State, Value>, handler: @escaping HandlerFunction<Environment, Value, Message>) {
    self.init(path: path, handler: .handler(handler))
  }

  init<Value>(path: WritableKeyPath<State, Value>, reducer: @escaping ReducerFunction<Value, Message>) {
    self.init(path: path, handler: .reducer(reducer))
  }
}

public func <> <Environment, State, Message>(
  _ first: MessageHandler<Environment, State, Message>,
  _ second: MessageHandler<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return first.merge(second)
}

public func <> <Environment, State, Message>(
  _ first: @escaping HandlerFunction<Environment, State, Message>,
  _ second: @escaping HandlerFunction<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return .handler(first, second)
}

public func <> <Environment, State, Message>(
  _ first: @escaping HandlerFunction<Environment, State, Message>,
  _ second: MessageHandler<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler.handler(first).merge(second)
}

public func <> <Environment, State, Message>(
  _ first: @escaping HandlerFunction<Environment, State, Message>,
  _ second: @escaping ReducerFunction<State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler.handler(first).merge(.reducer(second))
}

public func <> <Environment, State, Message>(
  _ first: MessageHandler<Environment, State, Message>,
  _ second: @escaping HandlerFunction<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return first.merge(second)
}

public func <> <Environment, State, Message>(
  _ first: MessageHandler<Environment, State, Message>,
  _ second: @escaping ReducerFunction<State, Message>
) -> MessageHandler<Environment, State, Message> {
  return first.merge(second)
}

public func <> <Environment, State, Message>(
  _ first: @escaping ReducerFunction<State, Message>,
  _ second: @escaping HandlerFunction<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler.reducer(first).merge(.handler(second))
}

public func <> <Environment, State, Message>(
  _ first: @escaping ReducerFunction<State, Message>,
  _ second: MessageHandler<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler.reducer(first).merge(second)
}

// KAO: The environment type can't be inferred

public func <> <State, Message>(
  _ first: @escaping ReducerFunction<State, Message>,
  _ second: @escaping ReducerFunction<State, Message>
) -> ReducerFunction<State, Message> {
  return { state, message in
    first(&state, message)
    second(&state, message)
  }
}
