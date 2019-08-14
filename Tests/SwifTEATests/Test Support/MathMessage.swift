// MIT License
//
// Copyright (c) 2019 Kevin O'Neill
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@testable import SwifTEA

protocol MathEnvironment {}

enum MathMessage: Equatable {
  case increment(_ amount: Int)
  case decrement(_ amount: Int)
  case multiply(_ factor: Int)
  case divide(_ factor: Int)
}

let incrementReducer = { (state: inout Int, message: MathMessage) -> Void in
  guard case let .increment(amount) = message else { return }

  state += amount
}

let decrementReducer = { (state: inout Int, message: MathMessage) -> Void in
  guard case let .decrement(amount) = message else { return }

  state -= amount
}

let multiplyReducer = { (state: inout Int, message: MathMessage) -> Void in
  guard case let .multiply(factor) = message else { return }

  state *= factor
}

let divideReducer = { (state: inout Int, message: MathMessage) -> Void in
  guard case let .divide(factor) = message else { return }

  state /= factor
}

typealias MathHandler = MessageHandler<MathEnvironment, Int, MathMessage>
let mathHandler: MathHandler = .reducer(incrementReducer, decrementReducer, multiplyReducer, divideReducer)
