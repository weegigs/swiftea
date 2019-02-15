//
//  Created by Kevin O'Neill on 4/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import WeeDux
import XCTest

class EventHandlerTestCase: XCTestCase {
  func augment(_ suffix: String) -> (([String], String) -> ([String], Command<Any, String>)) {
    return { (state, event) -> ([String], Command<Any, String>) in
      (state + ["\(event)-\(suffix)"], .none)
    }
  }

  func add(state: [String], event: String) -> ([String], Command<Any, String>) {
    return (state + [event], .none)
  }

  func testCombineTwoReducers() {
    let reducer = augment("a") <> augment("b")
    let (result, _) = reducer(["one"], "two")

    XCTAssertEqual(result, ["one", "two-a", "two-b"])
  }

  func testCombineThreeReducers() {
    let reducer = add <> augment("a") <> augment("b")
    let (result, _) = reducer(["one"], "two")

    XCTAssertEqual(result, ["one", "two", "two-a", "two-b"])
  }

  func testCombineOperater() {
    let reducer = add <> augment("a") <> augment("b")
    let (result, _) = reducer(["one"], "two")

    XCTAssertEqual(result, ["one", "two", "two-a", "two-b"])
  }
}
