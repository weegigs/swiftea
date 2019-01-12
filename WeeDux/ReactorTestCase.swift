import XCTest

@testable import WeeDux

final class ReactorTestCase: XCTestCase {
  var reactor: Reactor<Int, MathEvent>!

  override func setUp() {
    reactor = Reactor<Int, MathEvent>(state: 0, environment: [:], processor: math)
  }

  func testExecute() {
    let expectation = XCTestExpectation(description: "counter updated")

    let subscription = reactor.subscribe {
      if $0 == 4 {
        expectation.fulfill()
      }
    }

    reactor.dispatch(.increment(2))
    reactor.dispatch(.multiply(2))
    let state = reactor.read()

    wait(for: [expectation], timeout: 1)
    subscription.unsubscribe()

    XCTAssertEqual(state, 4)
  }

  func testSubscibeCurrentValueIsProvided() {
    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int!

    reactor.dispatch(.increment(2))
    let subsciption = reactor.subscribe {
      state = $0
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssertEqual(2, state)
    XCTAssertEqual(2, reactor.read())
  }

  func testSubscibeProvidesSubsequentValues() {
    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int = -1

    let subsciption = reactor.subscribe {
      state = $0
      if state == 3 {
        expectation.fulfill()
      }
    }

    reactor.dispatch(.increment(1))
    reactor.dispatch(.increment(1))
    reactor.dispatch(.increment(1))

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssert(state == 3)
    XCTAssert(reactor.read() == 3)
  }

  func testUpdatesAreDeliveredInOrder() {
    let expectation = XCTestExpectation(description: "subscriptions delivered")
    var state: [Int] = []

    let subsciption = reactor.subscribe {
      state.append($0)
      if $0 == 3 {
        expectation.fulfill()
      }
    }

    reactor.dispatch(.increment(1))
    reactor.dispatch(.increment(1))
    reactor.dispatch(.increment(1))

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssertEqual(state.count, 4)
    XCTAssertEqual(state, [0, 1, 2, 3])
    XCTAssertEqual(reactor.read(), 3)
  }
}
