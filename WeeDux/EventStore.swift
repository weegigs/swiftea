//
//  Publisher.swift
//  WeeDux
//
//  Created by Kevin O'Neill on 5/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Foundation

public protocol EventStoreType {
  typealias CompletionHandler = Projection<State, EventSet>.CompletionHandler
  typealias Sink = Projection<State, EventSet>.Sink
  typealias Source = Projection<State, EventSet>.Source

  associatedtype State
  associatedtype EventSet

  /// Disptch an update event
  var publish: Sink { get }
  var listen: Source { get }
}

public extension EventStoreType {
  public func publish(_ event: EventSet) {
    publish(event, noop)
  }

  public func publish(sync event: EventSet) -> State {
    let semaphore = DispatchSemaphore(value: 0)
    var result: State!
    publish(event) {
      result = $0
      semaphore.signal()
    }

    semaphore.wait()
    return result
  }
}
