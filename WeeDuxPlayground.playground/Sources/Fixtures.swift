import Foundation

public struct Fixture<Target> {
  public let target: Target

  fileprivate init(_ target: Target) {
    self.target = target
  }
}

public protocol FixtureCompatible {
  associatedtype Target
  var fixture: Fixture<Target> { get }
}

public extension FixtureCompatible {
  public var fixture: Fixture<Self> { return Fixture(self) }
}

extension String: FixtureCompatible {}

public extension Fixture where Target == String {
  var name: String { return "kevin" }
}
