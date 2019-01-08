//
//  Created by Kevin O'Neill on 29/12/18.
//
import XCTest

@testable import WeeDux

class ProjectionTestCase: XCTestCase {
  var projection: Projection<Int, MathEvent>!

  override func setUp() {
    projection = Projection(state: 0, reducer: mathReducer)
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testPublish() {
    let expectation = XCTestExpectation(description: "counter incremented")
    var state: Int!
    projection.publish(.increment(1)) {
      state = $0
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10.0)

    XCTAssert(state == 1)
    XCTAssert(projection.read() == 1)
  }

  func testPublishNoCallback() {
    let expectation = XCTestExpectation(description: "counter incremented")
    var state: Int!
    let subsciption = projection.subscribe {
      state = $0
      if state == 1 {
        expectation.fulfill()
      }
    }

    projection.publish(.increment(1))

    wait(for: [expectation], timeout: 10.0)

    XCTAssert(state == 1)
    XCTAssert(projection.read() == 1)

    subsciption.unsubscribe()
  }

  func testPublishSync() {
    let state = projection.publish(sync: .increment(1))

    XCTAssert(state == 1)
    XCTAssert(projection.read() == 1)
  }

  func testSubscibeInitialValueIsProvided() {
    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int!

    let subsciption = projection.subscribe {
      state = $0
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssert(state == 0)
    XCTAssert(projection.read() == 0)
  }

  func testSubscibeProvidesSubsequentValues() {
    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int = -1

    let subsciption = projection.subscribe {
      state = $0
      if state == 3 {
        expectation.fulfill()
      }
    }

    projection.publish(.increment(1))
    projection.publish(.increment(1))
    projection.publish(.increment(1))

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssert(state == 3)
    XCTAssert(projection.read() == 3)
  }

  func testUpdatesAreDeliveredInOrder() {
    let expectation = XCTestExpectation(description: "subscriptions delivered")
    var state: [Int] = []

    let subsciption = projection.subscribe {
      state.append($0)
      if $0 == 3 {
        expectation.fulfill()
      }
    }

    projection.publish(.increment(1))
    projection.publish(.increment(1))
    projection.publish(.increment(1))

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssertEqual(state.count, 4)
    XCTAssertEqual(state, [0, 1, 2, 3])
    XCTAssertEqual(projection.read(), 3)
  }

  func testListenersAreNotified() {
    let expectation = XCTestExpectation(description: "events delivered")
    var state: [MathEvent] = []

    let subsciption = projection.listen {
      state.append($0)
      if state.count == 3 {
        expectation.fulfill()
      }
    }

    projection.publish(.increment(1))
    projection.publish(.increment(2))
    projection.publish(.increment(3))

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssertEqual(state.count, 3)
    XCTAssertEqual(state, [.increment(1), .increment(2), .increment(3)])
  }
}
