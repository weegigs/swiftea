import WeeDux

public typealias SimpleObservable<State> = SimpleValueObservableStore<State, State>
public typealias SimpleEventStore<State, EventSet> = SimpleValueObservableStore<State, EventSet>

public class SimpleValueObservableStore<State, EventSet>: ObservableType, EventStoreType {
  private var state: State
  private let reducer: (State, EventSet) -> State
  private let queue: DispatchQueue

  private var subscriber: Subscription<State>.Listener?
  private var listener: Subscription<EventSet>.Listener?

  public lazy var listen: (@escaping (EventSet) -> Void) -> Subscription<EventSet> = _listen
  public lazy var subscribe: (@escaping (State) -> Void) -> Subscription<State> = _subscribe
  public lazy var publish: (EventSet, @escaping (State) -> Void) -> Void = _publish


  public init(_ initial: State, reducer: @escaping (State, EventSet) -> State, queue: DispatchQueue = DispatchQueue(label: "playground")) {
    self.state = initial
    self.reducer = reducer
    self.queue = queue
  }

  private func _publish(_ event: EventSet, complete: @escaping (State) -> Void) {
    let updated = reducer(state, event)
    state = updated
    queue.async {
      if let subscriber = self.subscriber {
        subscriber(updated)
      }
      complete(updated)
      if let listener = self.listener {
        listener(event)
      }
    }
  }

  private func _subscribe(_ subscriber: @escaping (State) -> Void) -> Subscription<State> {
    if nil != self.subscriber {
      fatalError("only supports a single subscriber")
    }

    self.subscriber = subscriber
    queue.async {
      subscriber(self.state)
    }

    return Subscription {
      self.subscriber = nil
    }
  }

  private func _listen(_ listener: @escaping (EventSet) -> Void) -> Subscription<EventSet> {
    if nil != self.listener {
      fatalError("only supports a single listener")
    }

    self.listener = listener

    return Subscription {
      self.listener = nil
    }
  }
}

public extension SimpleValueObservableStore where State == EventSet {
  public convenience init(_ initial: State, queue: DispatchQueue = DispatchQueue(label: "playground")) {
    self.init(initial, reducer: { _, e in e }, queue: queue )
  }
}


