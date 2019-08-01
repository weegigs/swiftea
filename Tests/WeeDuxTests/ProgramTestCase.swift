import Combine
import XCTest

@testable import WeeDux

final class ProgramTestCase: XCTestCase {
  var program: Program<Any, Int, MathEvent>!
  var count: Int = Int.min
  var state: Int = Int.min

  override func setUp() {
    count = 0
    state = 0

    let counter: Middleware<Any, Int, MathEvent> = { _, state, next in { event in
      self.count += 1
      next(event)
      self.state = state()
    } }

    program = Program(state: 0, environment: (), middleware: [counter], handler: math)
  }

  func testDispatch() {
    let expectation = XCTestExpectation(description: "counter updated")

    let subscription = program.subscribe {
      if $0 == 4 {
        expectation.fulfill()
      }
    }

    program.dispatch(.increment(2))
    program.dispatch(.multiply(2))
    let state = program.read()

    wait(for: [expectation], timeout: 1)
    subscription.cancel()

    XCTAssertEqual(state, 4)
  }

  func testMiddleware() {
    let expectation = XCTestExpectation(description: "counter updated")

    let subscription = program.subscribe {
      if $0 == 4 {
        expectation.fulfill()
      }
    }

    program.dispatch(.increment(2))
    program.dispatch(.multiply(2))

    wait(for: [expectation], timeout: 1)
    subscription.cancel()

    XCTAssertEqual(state, 4)
    XCTAssertEqual(count, 2)
  }

  func testSubscibeCurrentValueIsProvided() {
    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int!

    program.dispatch(.increment(2))
    let subsciption = program.subscribe {
      state = $0
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)
    subsciption.cancel()

    XCTAssertEqual(2, state)
    XCTAssertEqual(2, program.read())
  }

  func testSubscibeProvidesSubsequentValues() {
    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int = -1

    let subsciption = program.subscribe {
      state = $0
      if state == 3 {
        expectation.fulfill()
      }
    }

    program.dispatch(.increment(1))
    program.dispatch(.increment(1))
    program.dispatch(.increment(1))

    wait(for: [expectation], timeout: 1)

    subsciption.cancel()

    XCTAssert(state == 3)
    XCTAssert(program.read() == 3)
  }

  func testUpdatesAreDeliveredInOrder() {
    let expectation = XCTestExpectation(description: "subscriptions delivered")
    var state: [Int] = []

    let subsciption = program.subscribe {
      state.append($0)
      if $0 == 3 {
        expectation.fulfill()
      }
    }

    program.dispatch(.increment(1))
    program.dispatch(.increment(1))
    program.dispatch(.increment(1))

    wait(for: [expectation], timeout: 1)

    subsciption.cancel()

    XCTAssertEqual(state.count, 4)
    XCTAssertEqual(state, [0, 1, 2, 3])
    XCTAssertEqual(program.read(), 3)
  }
}
