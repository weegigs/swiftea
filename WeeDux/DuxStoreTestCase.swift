//
//  DuxStoreTestCase.swift
//  WeeDuxTests
//
//  Created by Kevin O'Neill on 4/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import XCTest

@testable import WeeDux

class DuxStoreTestCase: XCTestCase {
  var store: DuxStore<Int, MathEvent>!

  override func setUp() {
    store = DuxStore(state: 0, reducer: mathReducer)
  }

  override func tearDown() {
    store = nil
  }

  func testReadInitialValue() {
    XCTAssert(store.read() == 0)
  }

  func testPublishSync() {
    let result = store.publish(sync: .increment(1))

    XCTAssert(result == 1)
    XCTAssert(store.read() == 1)
  }

  func testPublish() {
    let expectation = XCTestExpectation(description: "subscription delivered")
    var result = -1

    store.publish(.increment(1)) {
      result = $0
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)

    XCTAssert(result == 1)
  }

  func testPublishNoCallback() {
    let expectation = XCTestExpectation(description: "counter incremented")
    var state: Int!
    let subsciption = store.subscribe {
      state = $0
      if state == 1 {
        expectation.fulfill()
      }
    }

    store.publish(.increment(1))

    wait(for: [expectation], timeout: 10.0)

    XCTAssert(state == 1)
    XCTAssert(store.read() == 1)

    subsciption.unsubscribe()
  }
}
