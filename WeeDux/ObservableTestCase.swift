//
//  ObservableTestCase.swift
//  WeeDuxTests
//
//  Created by Kevin O'Neill on 5/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import XCTest

@testable import WeeDux

class ObservableTestCase: XCTestCase {
  func just<T>(_ value: T) -> Observable<T> {
    return Observable<T> {
      $0(value)

      return Subscription {}
    }
  }

  func testMap() {
    var result: String!
    let sub = just(1)
      .map { "\($0)" }
      .subscribe {
        result = $0
      }

    sub.unsubscribe()

    XCTAssert(result == "1")
  }

  func testFilterPass() {
    var result: Int = -1
    _ = just(1)
      .filter { $0 > 0 }
      .subscribe {
        result = $0
      }

    XCTAssert(result == 1)
  }

  func testFilterOmit() {
    var result: Int = -1
    _ = just(1)
      .filter { $0 < 0 }
      .subscribe {
        result = $0
      }

    XCTAssert(result == -1)
  }

  func testUniqueValues() {
    let projection = Projection<Int, MathEvent>(state: 0) { state, event in
      guard
        case let .increment(value) = event,
        value % 2 == 0
      else {
        return state
      }

      return state + value
    }

    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int = 0

    var last = -1
    let subsciption = projection.unique().subscribe {
      state = $0
      XCTAssertNotEqual(state, last)
      last = state
      print(state)
      if state == 6 {
        expectation.fulfill()
      }
    }

    projection.publish(.increment(1))
    projection.publish(.increment(2))
    projection.publish(.increment(7))
    projection.publish(.increment(2))
    projection.publish(.increment(13))
    projection.publish(.increment(2))

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssertEqual(state, 6)
    XCTAssertEqual(projection.read(), 6)
  }

  func testSubscribeOnQueue() {
    let expectation = XCTestExpectation(description: "counter incremented")

    let observable = TestObservable(0)

    let subsciption = DispatchQueue.global(qos: .background).sync {
      return observable
        .deliver(on: .main)
        .subscribe { value in
          XCTAssert(Thread.isMainThread)
          if value == 1 {
            expectation.fulfill()
          }
        }
    }

    DispatchQueue.global(qos: .background).sync {
      observable.publish(1)
    }

    wait(for: [expectation], timeout: 10.0)

    subsciption.unsubscribe()
  }
}
