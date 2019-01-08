//
//  Created by Kevin O'Neill on 27/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Foundation

public struct Projection<State, EventSet>: EventStoreType, ObservableType {
  public typealias CompletionHandler = (_ state: State) -> Void
  public typealias Sink = (_ event: EventSet, _ completion: @escaping CompletionHandler) -> Void
  public typealias Source<T> = (_ listener: @escaping Subscription<T>.Listener) -> Subscription<T>

  public let listen: Source<EventSet>
  /// Subscribe to view updates
  public let subscribe: Source<State>
  /// Disptch an update event
  public let publish: Sink
  /// Read the current state
  public let read: () -> State

  public init(
    listen: @escaping (_ listener: @escaping Subscription<EventSet>.Listener) -> Subscription<EventSet>,
    subscribe: @escaping (_ listener: @escaping Subscription<State>.Listener) -> Subscription<State>,
    publish: @escaping Sink,
    read: @escaping () -> State
  ) {
    self.listen = listen
    self.subscribe = subscribe
    self.publish = publish
    self.read = read
  }
}

public extension Projection {
  public init(state: State, reducer: @escaping Reducer<State, EventSet>) {
    let view = ReducerProjection(state: state, reducer: reducer)

    self.init(listen: view.listen, subscribe: view.subscribe, publish: view.publish, read: view.read)
  }
}

private class ReducerProjection<State, EventSet> {
  typealias Subscriber<State> = (State) -> Void

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

  private let queue: DispatchQueue
  private let notifications: DispatchQueue
  private let reducer: Reducer<State, EventSet>

  private var subscriptions: MultiReaderSingleWriter<[String: ReducerSubscription<State>]>
  private var listeners: MultiReaderSingleWriter<[String: ReducerSubscription<EventSet>]>

  private var state: State {
    didSet { notify() }
  }

  init(state: State, reducer: @escaping Reducer<State, EventSet>) {
    queue = DispatchQueue(label: "com.weegigs.projection-\(UUID().uuidString)", attributes: .concurrent)
    notifications = DispatchQueue(label: "\(queue.label).notifications")
    subscriptions = MultiReaderSingleWriter([:])
    listeners = MultiReaderSingleWriter([:])

    self.reducer = reducer
    self.state = state
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

  func listen(subscriber: @escaping (EventSet) -> Void) -> Subscription<EventSet> {
    let key = UUID().uuidString
    let subscription = ReducerSubscription(subscriber: subscriber) { [weak self] in
      guard let self = self else { return }

      self.subscriptions.update { subscriptions in
        subscriptions.removeValue(forKey: key)
      }
    }

    listeners.update { subscriptions in
      subscriptions[key] = subscription
    }

    return Subscription(unsubscribe: subscription.unsubscribe)
  }

  func publish(event: EventSet, completed: @escaping (State) -> Void) {
    queue.async(flags: .barrier) {
      let state = self.reducer(self.state, event)
      self.state = state

      self.notifications.async {
        completed(state)
      }

      self.notifications.async {
        self.notify(event: event)
      }
    }
  }

  func read() -> State {
    return queue.sync {
      self.state
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

  private func notify(event: EventSet) {
    let listeners = self.listeners.value
    notifications.async {
      for (_, listener) in listeners {
        listener.notify(event)
      }
    }
  }
}
