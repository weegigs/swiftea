//
//  File.swift
//
//
//  Created by Kevin O'Neill on 13/8/19.
//

import SwifTEA

protocol TestMessage {}

struct TestState: Equatable {
  var string: [String]
  var number: Int
}

typealias TestEnvironment = MathEnvironment & StringEnvironment
typealias TestMesssageHandler = MessageHandler<TestEnvironment, TestState, TestMessage>

final class TestCaseEnvironment: TestEnvironment {
  var lastAppend: String?

  func updateLastAppend(_ value: String) {
    lastAppend = value
  }
}
