//
//  Created by Kevin O'Neill on 11/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

public typealias MessageHandlerFunction<Environment, State, Message> = (inout State, Message) -> (Command<Environment, Message>)

public struct MessageHandler<Environment, State, Message> {
  private let handlers: [MessageHandlerFunction<Environment, State, Message>]
  
  public func run(state: inout State, message: Message) -> (Command<Environment, Message>) {
    let commands: [Command<Environment, Message>] =  handlers.reduce(into: []) { commands, handler in
      commands.append(handler(&state, message))
    }
    
    return .batch(commands)
  }
  
  public func merge(_ handler: @escaping MessageHandlerFunction<Environment, State, Message>) -> MessageHandler<Environment, State, Message> {
    return MessageHandler(handlers: handlers + [handler])
  }
  
  public func merge(_ handler: MessageHandler<Environment, State, Message>) -> MessageHandler<Environment, State, Message> {
    return MessageHandler(handlers: handlers + handler.handlers)
  }

  public func merge(_ reducer: Reducer<State, Message>) -> MessageHandler<Environment, State, Message> {
    return merge(MessageHandler(reducer: reducer))
  }

  private init(handlers: [MessageHandlerFunction<Environment, State, Message>]) {
    self.handlers = handlers
  }
  
  public init(handler: @escaping MessageHandlerFunction<Environment, State, Message> ) {
    self.init(handlers: [handler])
  }
  
  public init(reducer: Reducer<State, Message>) {
    self.init { state, message in
      reducer.run(state: &state, message: message)
      return .none
    }
  }

}


extension MessageHandler {
  private init<Value>(path: WritableKeyPath<State, Value>, handler: MessageHandler<Environment, Value, Message>) {
    self.init { state, message in
      var value = state[keyPath: path]
      let command = handler.run(state: &value, message: message)
      state[keyPath: path] = value
      
      return command
    }
  }

  init<Value>(path: WritableKeyPath<State, Value>, handler: @escaping MessageHandlerFunction<Environment, Value, Message>) {
    self.init(path: path, handler: MessageHandler<Environment, Value, Message>(handler: handler))
  }

  init<Value>(path: WritableKeyPath<State, Value>, reducer: Reducer<Value, Message>) {
    self.init(path: path, handler: MessageHandler<Environment, Value, Message>(reducer: reducer))
  }
}

private extension MessageHandler {
  init(_ first: @escaping MessageHandlerFunction<Environment, State, Message>, _ second: @escaping MessageHandlerFunction<Environment, State, Message>) {
     self.init(handlers: [first, second])
   }

   init(_ first: @escaping MessageHandlerFunction<Environment, State, Message>, _ second: MessageHandler<Environment, State, Message>) {
     self.init(handlers: [first] + second.handlers)
   }

   init(_ first: @escaping MessageHandlerFunction<Environment, State, Message>, _ second: Reducer<State, Message>) {
     self.init(first, MessageHandler(reducer: second))
   }

   init(_ first: Reducer<State, Message>, _ second: @escaping MessageHandlerFunction<Environment, State, Message>) {
     self.init(handlers: MessageHandler(reducer: first).handlers + [second] )
   }

   init(_ first: Reducer<State, Message>, _ second: MessageHandler<Environment, State, Message>) {
     self.init(handlers: MessageHandler(reducer: first).handlers + second.handlers)
   }
}

public func <> <Environment, State, Message>(
  _ first: @escaping MessageHandlerFunction<Environment, State, Message>,
  _ second: @escaping MessageHandlerFunction<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler(first, second)
}

public func <> <Environment, State, Message>(
  _ first: @escaping MessageHandlerFunction<Environment, State, Message>,
  _ second: MessageHandler<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler(first, second)
}

public func <> <Environment, State, Message>(
  _ first: @escaping MessageHandlerFunction<Environment, State, Message>,
  _ second: Reducer<State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler(first, second)
}

public func <> <Environment, State, Message>(
  _ first: MessageHandler<Environment, State, Message>,
  _ second: @escaping MessageHandlerFunction<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return first.merge(second)
}

public func <> <Environment, State, Message>(
  _ first: MessageHandler<Environment, State, Message>,
  _ second: MessageHandler<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return first.merge(second)
}

public func <> <Environment, State, Message>(
  _ first: MessageHandler<Environment, State, Message>,
  _ second: Reducer<State, Message>
) -> MessageHandler<Environment, State, Message> {
  return first.merge(second)
}

public func <> <Environment, State, Message>(
  _ first: Reducer<State, Message>,
  _ second: @escaping MessageHandlerFunction<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler(first, second)
}

public func <> <Environment, State, Message>(
  _ first: Reducer<State, Message>,
  _ second: MessageHandler<Environment, State, Message>
) -> MessageHandler<Environment, State, Message> {
  return MessageHandler(first, second)
}

//public func handler<Environment, State, Message>(_ reducer: Reducer<State, Message>) -> MessageHandlerFunction<Environment, State, Message> {
//  return { state, message in (reducer.run(&state, message), .none) }
//}

//public func handler<Environment, State, Value, Message>(
//  _ path: WritableKeyPath<State, Value>,
//  _ handlers: MessageHandlerFunction<Environment, Value, Message>...
//) -> MessageHandlerFunction<Environment, State, Message> {
//  let handler = merge(handlers)
//  return { state, message in
//    let (update, commands) = handler(state[keyPath: path], message)
//    var updated = state
//    updated[keyPath: path] = update
//
//    return (updated, commands)
//  }
//}
