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

import Combine
import Dispatch
import Foundation

public typealias DispatchFunction<Message> = (Message) -> Void

public final class Program<Environment, State, Message>: Publisher {
  public typealias Output = State
  public typealias Failure = Never

  private let state: CurrentValueSubject<State, Never>
  private let updates: DispatchQueue
  private let effects: DispatchQueue

  private let environment: Environment
  private let handler: MessageHandler<Environment, State, Message>
  private let middleware: [Middleware<Environment, State, Message>]

  private lazy var dispatcher: DispatchFunction<Message> = {
    let run = { [unowned self] (message: Message) in
      var state = self.state.value
      let command = self.handler.run(state: &state, message: message)
      self.state.value = state
      self.execute(command)
    }
    let read = { [unowned self] in self.state.value }

    return middleware.reduce(run) { next, ware in ware(environment, read, next) }
  }()

  public init(
    state: State,
    environment: Environment,
    middleware: [Middleware<Environment, State, Message>],
    handler: MessageHandler<Environment, State, Message>
  ) {
    updates = DispatchQueue(label: "com.weegigs.dispatcher-\(UUID().uuidString)", attributes: .concurrent)
    effects = DispatchQueue(label: "\(updates.label).effects", attributes: .concurrent)

    self.state = CurrentValueSubject(state)
    self.environment = environment
    self.middleware = middleware.reversed()
    self.handler = handler
  }

  public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, S.Input == State {
    state.receive(subscriber: subscriber)
  }

  public func subscribe(_ subscriber: @escaping (State) -> Void) -> Cancellable {
    return sink { value in subscriber(value) }
  }

  public func read() -> State {
    return updates.sync {
      self.state.value
    }
  }

  public func dispatch(_ message: Message) {
    updates.async(flags: .barrier) {
      self.dispatcher(message)
    }
  }

  public func execute(_ command: Command<Environment, Message>) {
    effects.async {
      command.run(self.environment, self.dispatch)
    }
  }
}
