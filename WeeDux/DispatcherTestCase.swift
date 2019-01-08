import XCTest

@testable import WeeDux

final class DispatcherTestCase: XCTestCase {
  func testExecute() {
    let projection = Projection(state: 0, reducer: mathReducer)
    let dispatcher = Dispatcher(projection: projection)

    let expectation = XCTestExpectation(description: "counter updated")
    var state: Int!
    dispatcher.execute { read, dispatch in
      dispatch(.increment(2)) {
        state = $0
        XCTAssert(read() == state)

        dispatch(.multiply(state)) {
          state = $0
          expectation.fulfill()
        }
      }
    }

    wait(for: [expectation], timeout: 1)
    XCTAssert(state == 4)
  }
}
