//
//  File.swift
//
//
//  Created by Kevin O'Neill on 13/8/19.
//

import SwifTEA

protocol StringEnvironment {
  var lastAppend: String? { get }
  func updateLastAppend(_ value: String)
}

enum StringMessage {
  case noop
  case append(String)
  case augment(String)
}

typealias StringMessageHandler = MessageHandler<StringEnvironment, [String], StringMessage>
typealias StringCommand = Command<StringEnvironment, StringMessage>

func updateLastAppend(_ value: String) -> StringCommand {
  StringCommand { environment, publish in
    environment.updateLastAppend(value)

    publish(.noop)
  }
}

//  func augment(_ suffix: String) -> ((inout [String], String)  {
//    return { (state, message) -> Command<Any, String> in
//      state += ["\(message)-\(suffix)"]
//    }
//  }
//
let append = StringMessageHandler { (state, message) -> StringCommand in
  guard case let .append(value) = message else {
    return .none
  }

  state += [value]

  return updateLastAppend(value)
}

let stringHandler = append
