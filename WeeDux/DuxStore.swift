//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

public struct DuxStore<State, EventSet>: EventStoreType, ObservableType, DispatcherType {
  public let listen: Projection<State, EventSet>.Source<EventSet>
  public let subscribe: Projection<State, EventSet>.Source<State>
  public let read: () -> State

  public let publish: Projection<State, EventSet>.Sink
  public let execute: (@escaping Dispatcher<State, EventSet>.Thunk) -> Void
}

public extension DuxStore {
  public init(state: State, reducer: @escaping Reducer<State, EventSet>) {
    let projection = Projection(state: state, reducer: reducer)
    let dispatcher = Dispatcher(projection: projection)
    let store = SingleProjectionStore(projection: projection, dispatcher: dispatcher)

    self.init(
      listen: store.listen,
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

  func listen(listener: @escaping (EventSet) -> Void) -> Subscription<EventSet> {
    return projection.listen(listener)
  }

  func subscribe(subscriber: @escaping (State) -> Void) -> Subscription<State> {
    return projection.subscribe(subscriber)
  }

  func read() -> State {
    return projection.read()
  }

  func publish(event: EventSet, onComplete: @escaping (State) -> Void) {
    projection.publish(event, onComplete)
  }

  func execute(command: @escaping Dispatcher<State, EventSet>.Thunk) {
    dispatcher.execute(command)
  }
}
