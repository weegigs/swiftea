//
//  Fixtures.swift
//  WeeDuxTests
//
//  Created by Kevin O'Neill on 29/12/18.
//

@testable import WeeDux

enum MathEvent: Equatable {
  case increment(_ amount: Int)
  case decrement(_ amount: Int)
  case multiply(_ factor: Int)
  case divide(_ factor: Int)
}

let incrementReducer = { (state: inout Int, message: MathEvent) -> Void in
  guard case let .increment(amount) = message else { return }

  state += amount
}

let decrementReducer = { (state: inout Int, message: MathEvent) -> Void in
  guard case let .decrement(amount) = message else { return }

  state -= amount
}

let multiplyReducer = { (state: inout Int, message: MathEvent) -> Void in
  guard case let .multiply(factor) = message else { return }

  state *= factor
}

let divideReducer = { (state: inout Int, message: MathEvent) -> Void in
  guard case let .divide(factor) = message else { return }

  state /= factor
}

let reducer = incrementReducer <> decrementReducer <> multiplyReducer <> divideReducer

let math: MessageHandler<Any, Int, MathEvent> = MessageHandler(reducer: reducer)
