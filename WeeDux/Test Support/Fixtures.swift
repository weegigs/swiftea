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

let incrementReducer = { (state: Int, event: MathEvent) -> Int in
  guard case let .increment(amount) = event else { return state }

  return state + amount
}

let decrementReducer = { (state: Int, event: MathEvent) -> Int in
  guard case let .decrement(amount) = event else { return state }

  return state - amount
}

let multiplyReducer = { (state: Int, event: MathEvent) -> Int in
  guard case let .multiply(factor) = event else { return state }

  return state * factor
}

let divideReducer = { (state: Int, event: MathEvent) -> Int in
  guard case let .divide(factor) = event else { return state }

  return state / factor
}

let math: EventProcessor<Any, Int, MathEvent> = from(incrementReducer, decrementReducer, multiplyReducer, divideReducer)
