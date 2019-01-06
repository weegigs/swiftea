//
//  Created by Kevin O'Neill on 27/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Foundation

public struct Projection<State, EventSet>: PublisherType, ObservableType {
  public typealias CompletionHandler = (_ state: State) -> Void
  public typealias Publisher = (_ event: EventSet, _ completion: @escaping CompletionHandler) -> Void

  /// Subscribe to view updates
  public let subscribe: (_ listener: @escaping Subscription<State>.Listener) -> Subscription<State>
  /// Disptch an update event
  public let publish: Publisher
  /// Read the current state
  public let read: () -> State

  public init(
    subscribe: @escaping (_ listener: @escaping Subscription<State>.Listener) -> Subscription<State>,
    publish: @escaping Publisher,
    read: @escaping () -> State
  ) {
    self.subscribe = subscribe
    self.publish = publish
    self.read = read
  }
}

public extension Projection {
  public init(state: State, reducer: @escaping Reducer<State, EventSet>) {
    let view = ReducerProjection(state: state, reducer: reducer)

    self.init(subscribe: view.subscribe, publish: view.publish, read: view.read)
  }
}

private class ReducerProjection<State, EventSet> {
  typealias Subscriber<State> = (State) -> Void

  private struct ReducerSubscription {
    let subscriber: Subscriber<State>
    let remove: () -> Void

    func notify(_ state: State) {
      subscriber(state)
    }

    func unsubscribe() {
      remove()
    }
  }

  private let queue: DispatchQueue
  private let notifications: DispatchQueue
  private let reducer: Reducer<State, EventSet>

  private var subscriptions: MultiReaderSingleWriter<[String: ReducerSubscription]>
  private var state: State {
    didSet { notify() }
  }

  init(state: State, reducer: @escaping Reducer<State, EventSet>) {
    queue = DispatchQueue(label: "com.weegigs.projection-\(UUID().uuidString)", attributes: .concurrent)
    notifications = DispatchQueue(label: "\(queue.label).notifications")
    subscriptions = MultiReaderSingleWriter([:])

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

  func publish(event: EventSet, completed: @escaping (State) -> Void) {
    queue.async(flags: .barrier) {
      let state = self.reducer(self.state, event)
      self.state = state

      self.notifications.async {
        completed(state)
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
}
