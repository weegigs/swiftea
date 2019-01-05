import WeeDux

public class PlayObservable<State>: ObservableType, PublisherType {
  public typealias EventSet = State

  private let initial: State
  private let queue: DispatchQueue

  private var subscriber: Subscription<State>.Listener?

  public lazy var subscribe: (@escaping (State) -> Void) -> Subscription<State> = _subscribe
  public lazy var publish: (State, @escaping (State) -> Void) -> Void = _publish

  public init(_ initial: State, queue: DispatchQueue = DispatchQueue(label: "playground")) {
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
}


