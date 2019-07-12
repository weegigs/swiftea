//
//  TestObservable.swift
//  WeeDuxTests
//
//  Created by Kevin O'Neill on 5/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Foundation

import WeeDux

class TestObservable<State>: ObservableType {
  typealias Event = State

  private let queue: DispatchQueue

  private var subscriber: Subscription<State>.Listener?

  private(set) var state: State
  lazy var subscribe: (@escaping (State) -> Void) -> Subscription<State> = _subscribe

  init(_ initial: State, queue: DispatchQueue = DispatchQueue(label: "test")) {
    state = initial
    self.queue = queue
  }

  func push(_ value: State) {
    guard let subscriber = subscriber else {
      return
    }

    state = value
    queue.async {
      subscriber(self.state)
    }
  }

  private func _subscribe(_ subscriber: @escaping (State) -> Void) -> Subscription<State> {
    if self.subscriber != nil {
      fatalError("test only supports a single subscriber")
    }

    self.subscriber = subscriber
    queue.async {
      subscriber(self.state)
    }

    return Subscription {
      self.subscriber = nil
    }
  }
}
