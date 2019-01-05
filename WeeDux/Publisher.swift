//
//  Publisher.swift
//  WeeDux
//
//  Created by Kevin O'Neill on 5/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Foundation

public protocol PublisherType {
  typealias CompletionHandler = Projection<State, EventSet>.CompletionHandler
  typealias Publisher = Projection<State, EventSet>.Publisher

  associatedtype State
  associatedtype EventSet

  /// Disptch an update event
  var publish: Publisher { get }
}

public extension PublisherType {
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
