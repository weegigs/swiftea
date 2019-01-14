//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Dispatch

public struct Reactor<State, Event>: ObservableType {
  public let dispatch: (Event) -> Void
  public let subscribe: (_ listener: @escaping Subscription<State>.Listener) -> Subscription<State>
  public let read: () -> State

  public init(dispatch: @escaping (Event) -> Void,
              subscribe: @escaping (_ listener: @escaping Subscription<State>.Listener) -> Subscription<State>,
              read: @escaping () -> State) {
    self.dispatch = dispatch
    self.subscribe = subscribe
    self.read = read
  }
}

public extension Reactor {
  public init<Environment>(state: State, environment: Environment, handler: @escaping EventHandler<Environment, State, Event>) {
    let reactor = BaseReactor(state: state, environment: environment, handler: handler)

    self.init(
      dispatch: reactor.dispatch,
      subscribe: reactor.subscribe,
      read: reactor.read
    )
  }
}

// internal

fileprivate class BaseReactor<Environment, State, EventSet> {
  typealias Subscriber<State> = (State) -> Void

  private let updates: DispatchQueue
  private let effects: DispatchQueue
  private let notifications: DispatchQueue

  fileprivate let environment: Environment
  private let handler: EventHandler<Environment, State, EventSet>

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

  init(state: State, environment: Environment, handler: @escaping EventHandler<Environment, State, EventSet>) {
    updates = DispatchQueue(label: "com.weegigs.dispatcher-\(UUID().uuidString)", attributes: .concurrent)
    effects = DispatchQueue(label: "\(updates.label).effects", attributes: .concurrent)
    notifications = DispatchQueue(label: "\(updates.label).notifications")
    subscriptions = MultiReaderSingleWriter([:])

    self.state = state
    self.environment = environment
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

  func dispatch(event: EventSet) {
    updates.async(flags: .barrier) {
      let (state, command) = self.handler(self.state, event)

      self.state = state
      self.run(command: command)
    }
  }

  func run(command: Command<Environment, EventSet>) {
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
