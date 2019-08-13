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

import SwifTEA
import XCTest

extension MathMessage: TestMessage {}
extension StringMessage: TestMessage {}

class KeyPathTestCase: XCTestCase {
  func testLiftReducer() {
    let lifted: TestMesssageHandler = mathHandler.lift(\.number)
    var state = TestState(string: ["hello"], number: 0)

    _ = lifted.run(state: &state, message: MathMessage.increment(1))

    XCTAssertEqual(state, TestState(string: ["hello"], number: 1))
  }

  func testLiftHandler() {
    let lifted: TestMesssageHandler = stringHandler.lift(\.string)

    var state = TestState(string: ["hello"], number: 0)

    let command = lifted.run(state: &state, message: StringMessage.append("world"))
    XCTAssertEqual(state, TestState(string: ["hello", "world"], number: 0))

    let environment = TestCaseEnvironment()
    var published: TestMessage?

    let expectation = XCTestExpectation(description: "command executed")
    let publish: (TestMessage) -> Void = { message in
      published = message
      expectation.fulfill()
    }

    command.run(environment, publish)

    wait(for: [expectation], timeout: 120)
    XCTAssertEqual(environment.lastAppend, "world")

    guard
      let stringMessage = published as? StringMessage else {
      XCTFail()
      return
    }

    switch stringMessage {
    case .noop:
      break
    default:
      XCTFail()
    }
  }
}
