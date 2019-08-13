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

class MessageHandlerTestCase: XCTestCase {
  func augment(_ suffix: String) -> ((inout [String], String) -> Command<Any, String>) {
    return { (state, message) -> Command<Any, String> in
      state += ["\(message)-\(suffix)"]

      return .none
    }
  }

  func add(state: inout [String], message: String) -> Command<Any, String> {
    state += [message]

    return .none
  }

  func testCombineTwoReducers() {
    let reducer = augment("a") <> augment("b")
    var result = ["one"]

    _ = reducer.run(state: &result, message: "two")

    XCTAssertEqual(result, ["one", "two-a", "two-b"])
  }

  func testCombineThreeReducers() {
    let reducer = add <> augment("a") <> augment("b")
    var result = ["one"]

    _ = reducer.run(state: &result, message: "two")

    XCTAssertEqual(result, ["one", "two", "two-a", "two-b"])
  }

  func testCombineOperater() {
    let reducer = add <> augment("a") <> augment("b")
    var result = ["one"]

    _ = reducer.run(state: &result, message: "two")

    XCTAssertEqual(result, ["one", "two", "two-a", "two-b"])
  }
}
