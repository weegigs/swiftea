//
//  Created by Kevin O'Neill on 4/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import WeeDux
import XCTest

class ReducerTestCase: XCTestCase {
  func augment(_ suffix: String) -> (([String], String) -> [String]) {
    return { (state, event) -> [String] in
      state + ["\(event)-\(suffix)"]
    }
  }

  func add(state: [String], event: String) -> [String] {
    return state + [event]
  }

  func testCombineTwoReducers() {
    let reducer = combineReducers(augment("a"), augment("b"))
    let result = reducer(["one"], "two")

    XCTAssert(result == ["one", "two-a", "two-b"])
  }

  func testCombineThreeReducers() {
    let reducer = combineReducers(add, augment("a"), augment("b"))
    let result = reducer(["one"], "two")

    XCTAssert(result == ["one", "two", "two-a", "two-b"])
  }

  func testCombineOperater() {
    let reducer = add <> augment("a") <> augment("b")
    let result = reducer(["one"], "two")

    XCTAssert(result == ["one", "two", "two-a", "two-b"])
  }
}
