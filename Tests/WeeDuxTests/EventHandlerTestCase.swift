//
//  Created by Kevin O'Neill on 4/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import WeeDux
import XCTest

class EventHandlerTestCase: XCTestCase {
  func augment(_ suffix: String) -> ((inout [String], String) -> Command<Any, String>) {
    return { ( state, message) -> Command<Any, String> in
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
