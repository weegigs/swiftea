//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

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
    let cancellable = sink(
      receiveCompletion: { _ in },
      receiveValue: { value in subscriber(value) }
    )

    return cancellable
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
