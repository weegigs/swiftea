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

  func testDistinct() {
    let projection = TestObservable(0)

    let expectation = XCTestExpectation(description: "subscription delivered")
    var state: Int = 0

    var last = -1
    let subsciption = projection.distinct().subscribe {
      state = $0
      XCTAssertNotEqual(state, last)
      last = state
      print(state)
      if state == 3 {
        expectation.fulfill()
      }
    }

    projection.push(1)
    projection.push(2)
    projection.push(2)
    projection.push(2)
    projection.push(13)
    projection.push(3)

    wait(for: [expectation], timeout: 1)

    subsciption.unsubscribe()

    XCTAssertEqual(projection.state, 3)
  }

  func testDeliverOnQueue() {
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
      observable.push(1)
    }

    wait(for: [expectation], timeout: 10.0)

    subsciption.unsubscribe()
  }

  func testSubscribeOnQueue() {
    let expectation = XCTestExpectation(description: "counter incremented")

    let observable = TestObservable(0)

    let subsciption = DispatchQueue.global(qos: .background).sync {
      return observable
        .subscribe(on: .main) { value in
          XCTAssert(Thread.isMainThread)
          if value == 1 {
            expectation.fulfill()
          }
        }
    }

    DispatchQueue.global(qos: .background).sync {
      observable.push(1)
    }

    wait(for: [expectation], timeout: 10.0)

    subsciption.unsubscribe()
  }
}
