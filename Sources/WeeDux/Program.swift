//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Combine
import Dispatch
import Foundation

public typealias DispatchFunction<Event> = (Event) -> Void

public final class Program<Environment, State, Event>: Publisher {
  public typealias Output = State
  public typealias Failure = Never

  private let state: CurrentValueSubject<State, Never>
  private let updates: DispatchQueue
  private let effects: DispatchQueue

  private let environment: Environment
  private let handler: EventHandler<Environment, State, Event>
  private let middleware: [Middleware<Environment, State, Event>]

  private lazy var dispatcher: DispatchFunction<Event> = {
    let run = { [unowned self] (event: Event) in
      let (state, command) = self.handler(self.state.value, event)
      self.state.value = state
      self.execute(command)
    }
    let read = { [unowned self] in self.state.value }

    return middleware.reduce(run) { next, ware in ware(environment, read, next) }
  }()

  public init(
    state: State,
    environment: Environment,
    middleware: [Middleware<Environment, State, Event>],
    handler: @escaping EventHandler<Environment, State, Event>
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
    let cancellable = self.sink(
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

  public func dispatch(_ event: Event) {
    updates.async(flags: .barrier) {
      self.dispatcher(event)
    }
  }

  public func execute(_ command: Command<Environment, Event>) {
    effects.async {
      command.run(self.environment, self.dispatch)
    }
  }
}
