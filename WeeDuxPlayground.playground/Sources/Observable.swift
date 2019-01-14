import WeeDux

public class TestObservable<State>: ObservableType {
  typealias Event = State

  private let queue: DispatchQueue

  private var subscriber: Subscription<State>.Listener?

  public private(set) var state: State
  public lazy var subscribe: (@escaping (State) -> Void) -> Subscription<State> = _subscribe

  public init(_ initial: State, queue: DispatchQueue = DispatchQueue(label: "test")) {
    state = initial
    self.queue = queue
  }

  public func push(_ value: State) {
    guard let subscriber = subscriber else {
      return
    }

      queue.async {
        self.state = value
        subscriber(value)
      }
  }

  public func push(sync value: State) {
    guard let subscriber = subscriber else {
      return
    }

      queue.sync {
        self.state = value
        subscriber(value)
      }
  }

  private func _subscribe(_ subscriber: @escaping (State) -> Void) -> Subscription<State> {
    if nil != self.subscriber {
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
