// MIT License
//
// Copyright (c) 2019 Kevin O'Neill
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

    let counter: Middleware<Any, Int, MathEvent> = { _, state, next in { message in
      self.count += 1
      next(message)
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
