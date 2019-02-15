//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Dispatch

public typealias DispatchFunction<Event> = (Event) -> Void

public struct Program<Environment, State, Event>: ObservableType {
  public let execute: (Command<Environment, Event>) -> Void
  public let dispatch: DispatchFunction<Event>
  public let subscribe: (_ listener: @escaping Subscription<State>.Listener) -> Subscription<State>
  public let read: () -> State

  public init(
    execute: @escaping (Command<Environment, Event>) -> Void,
    dispatch: @escaping (Event) -> Void,
    subscribe: @escaping (_ listener: @escaping Subscription<State>.Listener) -> Subscription<State>,
    read: @escaping () -> State
  ) {
    self.execute = execute
    self.dispatch = dispatch
    self.subscribe = subscribe
    self.read = read
  }
}

public extension Program {
  public init(
    state: State,
    environment: Environment,
    middleware: [Middleware<State, Event>],
    handler: @escaping EventHandler<Environment, State, Event>
  ) {
    let program = BaseProgram(state: state, environment: environment, middleware: middleware, handler: handler)

    self.init(
      execute: program.execute,
      dispatch: program.dispatch,
      subscribe: program.subscribe,
      read: program.read
    )
  }
}

// internal

fileprivate class BaseProgram<Environment, State, Event> {
  typealias Subscriber<State> = (State) -> Void

  private let updates: DispatchQueue
  private let effects: DispatchQueue
  private let notifications: DispatchQueue

  private let environment: Environment
  private let handler: EventHandler<Environment, State, Event>
  private let middleware: [Middleware<State, Event>]
  private lazy var dispatcher: DispatchFunction<Event> = {
    let run = { [unowned self] (event: Event) in
      let (state, command) = self.handler(self.state, event)
      self.state = state
      self.execute(command: command)
    }
    let read = { [unowned self] in self.state }

    return middleware.reversed().reduce(run, { next, ware in ware(read, next) })
  }()

  private var subscriptions: MultiReaderSingleWriter<[String: ReducerSubscription<State>]>
  private var state: State {
    didSet { notify() }
  }

  private struct ReducerSubscription<T> {
    let subscriber: Subscriber<T>
    let remove: () -> Void

    func notify(_ update: T) {
      subscriber(update)
    }

    func unsubscribe() {
      remove()
    }
  }

  init(
    state: State,
    environment: Environment,
    middleware: [Middleware<State, Event>],
    handler: @escaping EventHandler<Environment, State, Event>
  ) {
    updates = DispatchQueue(label: "com.weegigs.dispatcher-\(UUID().uuidString)", attributes: .concurrent)
    effects = DispatchQueue(label: "\(updates.label).effects", attributes: .concurrent)
    notifications = DispatchQueue(label: "\(updates.label).notifications")
    subscriptions = MultiReaderSingleWriter([:])

    self.state = state
    self.environment = environment
    self.middleware = middleware
    self.handler = handler
  }

  func subscribe(subscriber: @escaping (State) -> Void) -> Subscription<State> {
    let key = UUID().uuidString
    let subscription = ReducerSubscription(subscriber: subscriber) { [weak self] in
      guard let self = self else { return }

      self.subscriptions.update { subscriptions in
        subscriptions.removeValue(forKey: key)
      }
    }

    subscriptions.update { subscriptions in
      subscriptions[key] = subscription
    }

    let state = read()
    notifications.async {
      subscription.notify(state)
    }

    return Subscription(unsubscribe: subscription.unsubscribe)
  }

  func read() -> State {
    return updates.sync {
      self.state
    }
  }

  func dispatch(event: Event) {
    updates.async(flags: .barrier) {
      self.dispatcher(event)
    }
  }

  func execute(command: Command<Environment, Event>) {
    effects.async {
      command.run(self.environment, self.dispatch)
    }
  }

  private func notify() {
    let subscriptions = self.subscriptions.value
    let state = self.state
    notifications.async {
      for (_, subscription) in subscriptions {
        subscription.notify(state)
      }
    }
  }
}
