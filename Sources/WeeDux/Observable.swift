//
//  Created by Kevin O'Neill on 5/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Dispatch

public struct Subscription<State> {
  public typealias Listener = (_ state: State) -> Void
  public let unsubscribe: () -> Void

  public init(unsubscribe: @escaping () -> Void) {
    self.unsubscribe = unsubscribe
  }
}

public protocol ObservableType {
  associatedtype State

  var subscribe: (_ subscriber: @escaping Subscription<State>.Listener) -> Subscription<State> { get }
}

public struct Observable<State>: ObservableType {
  public let subscribe: (_ subscriber: @escaping Subscription<State>.Listener) -> Subscription<State>
}

public extension ObservableType {
  func filter(predicate: @escaping (State) -> Bool) -> Observable<State> {
    return Observable { subscriber in
      self.subscribe {
        if predicate($0) {
          subscriber($0)
        }
      }
    }
  }
}

public extension ObservableType {
  func map<T>(transform: @escaping (State) -> T) -> Observable<T> {
    return Observable<T> { (_ subscriber: @escaping Subscription<T>.Listener) -> Subscription<T> in
      let subscription = self.subscribe {
        subscriber(transform($0))
      }

      return Subscription {
        subscription.unsubscribe()
      }
    }
  }
}

public extension ObservableType where State: Equatable {
  func distinct() -> Observable<State> {
    return Observable { subscriber in
      var previous: State?

      return self.subscribe { state in
        guard let last = previous else {
          previous = state
          subscriber(state)
          return
        }

        if last != state {
          previous = state
          subscriber(state)
        }
      }
    }
  }
}

public extension ObservableType {
  func deliver(on queue: DispatchQueue) -> Observable<State> {
    return Observable { subscriber in
      self.subscribe { state in
        queue.sync {
          subscriber(state)
        }
      }
    }
  }
}

public extension ObservableType {
  func subscribe(on queue: DispatchQueue, subscriber: @escaping Subscription<State>.Listener) -> Subscription<State> {
    return deliver(on: queue).subscribe(subscriber)
  }
}