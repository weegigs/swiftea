//
//  TestObservable.swift
//  WeeDuxTests
//
//  Created by Kevin O'Neill on 5/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Foundation

import WeeDux

class TestObservable<State>: ObservableType, EventStoreType {
  typealias EventSet = State

  private let initial: State
  private let queue: DispatchQueue

  private var subscriber: Subscription<State>.Listener?
  private var listener: Subscription<EventSet>.Listener?

  lazy var listen: (@escaping (State) -> Void) -> Subscription<State> = _listen
  lazy var subscribe: (@escaping (State) -> Void) -> Subscription<State> = _subscribe
  lazy var publish: (State, @escaping (State) -> Void) -> Void = _publish

  init(_ initial: State, queue: DispatchQueue = DispatchQueue(label: "test")) {
    self.initial = initial
    self.queue = queue
  }

  private func _publish(_ value: State, complete: @escaping (State) -> Void) {
    guard let subscriber = subscriber else {
      return
    }

    queue.async {
      subscriber(value)
      complete(value)
    }
  }

  private func _subscribe(_ subscriber: @escaping (State) -> Void) -> Subscription<State> {
    if nil != self.subscriber {
      fatalError("test only supports a single subscriber")
    }

    self.subscriber = subscriber
    queue.async {
      subscriber(self.initial)
    }

    return Subscription {
      self.subscriber = nil
    }
  }

  private func _listen(_ listener: @escaping (EventSet) -> Void) -> Subscription<EventSet> {
    if nil != self.listener {
      fatalError("test only supports a single listener")
    }

    self.listener = listener

    return Subscription {
      self.listener = nil
    }
  }
}
