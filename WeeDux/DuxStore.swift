//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

public struct DuxStore<State, EventSet>: PublisherType, ObservableType, ExecutorType {
  public let subscribe: (@escaping (State) -> Void) -> Subscription<State>
  public let read: () -> State

  public let publish: Projection<State, EventSet>.Publisher
  public let execute: (@escaping Dispatcher<State, EventSet>.Thunk) -> Void
}

public extension DuxStore {
  public init(state: State, reducer: @escaping Reducer<State, EventSet>) {
    let projection = Projection(state: state, reducer: reducer)
    let dispatcher = Dispatcher(projection: projection)
    let store = SingleProjectionStore(projection: projection, dispatcher: dispatcher)

    self.init(
      subscribe: store.subscribe,
      read: store.read,
      publish: store.publish,
      execute: store.execute
    )
  }
}

struct SingleProjectionStore<State, EventSet> {
  private let projection: Projection<State, EventSet>
  private let dispatcher: Dispatcher<State, EventSet>

  init(projection: Projection<State, EventSet>, dispatcher: Dispatcher<State, EventSet>) {
    self.projection = projection
    self.dispatcher = dispatcher
  }

  func subscribe(subscriber: @escaping (State) -> Void) -> Subscription<State> {
    return projection.subscribe(subscriber)
  }

  func read() -> State {
    return projection.read()
  }

  func publish(event: EventSet, onComplete: @escaping (State) -> Void) {
    dispatcher.publish(event, onComplete)
  }

  func execute(command: @escaping Dispatcher<State, EventSet>.Thunk) {
    dispatcher.execute(command)
  }
}
