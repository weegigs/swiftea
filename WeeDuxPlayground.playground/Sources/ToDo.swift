import Foundation

public struct ToDo: Equatable {
  public enum ToDoStatus: Equatable {
    case incomplete
    case completed(on: Date)
  }

  public let id: String
  
  public var title: String
  public var status: ToDoStatus

  public init(title: String) {
    id = UUID().uuidString
    status = .incomplete

    self.title = title
  }

  public var isComplete: Bool {
    if case .incomplete = status {
      return false
    }

    return true
  }
}
