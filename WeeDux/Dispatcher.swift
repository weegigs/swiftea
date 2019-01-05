//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Dispatch
import Foundation

public protocol ExecutorType {
  associatedtype State
  associatedtype EventSet

  var execute: (@escaping Dispatcher<State, EventSet>.Thunk) -> Void { get }
}

public struct Dispatcher<State, EventSet>: ExecutorType, PublisherType {
  public typealias Publisher = Projection<State, EventSet>.Publisher
  public typealias Thunk = (@escaping () -> State, @escaping Publisher) -> Void

  public let publish: Publisher
  public let execute: (@escaping Thunk) -> Void
}

public extension Dispatcher {
  public init(projection: Projection<State, EventSet>) {
    let dispatcher = SingleProjectionDispatcher(projection: projection)

    self.init(
      publish: dispatcher.publish,
      execute: dispatcher.execute
    )
  }
}

struct SingleProjectionDispatcher<State, EventSet> {
  private let projection: Projection<State, EventSet>

  init(projection: Projection<State, EventSet>) {
    self.projection = projection
  }

  func publish(event: EventSet, completionHandler: @escaping Projection<State, EventSet>.CompletionHandler) {
    projection.publish(event, completionHandler)
  }

  func execute(command: @escaping Dispatcher<State, EventSet>.Thunk) {
    let reader = projection.read
    let publisher = publish

    command(reader, publisher)
  }
}
