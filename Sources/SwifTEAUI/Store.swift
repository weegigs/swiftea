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

import Combine
import SwifTEA
import SwiftUI

public final class Store<Environment, Model, Message>: ObservableObject {
  public final class Dispatcher: ObservableObject {
    private let program: Program<Environment, Model, Message>

    public func send(_ message: Message) {
      program.dispatch(message)
    }

    public func send(_ command: SwifTEA.Command<Environment, Message>) {
      program.execute(command)
    }

    init(program: Program<Environment, Model, Message>) {
      self.program = program
    }
  }

  @Published public private(set) var model: Model
  public let dispatcher: Dispatcher

  private var subscription: Cancellable?

  public init(program: Program<Environment, Model, Message>) {
    model = program.read()
    dispatcher = Dispatcher(program: program)

    subscription = program
      .receive(on: RunLoop.main)
      .sink { [weak self] value in
        self?.model = value
      }
  }

  deinit {
    subscription?.cancel()
  }
}

#if DEBUG

  let stringProgram = Program<[String: Any], [String], String>(
    initial: ["Hello World"],
    environment: [:],
    handler: .reducer { state, message in state.append(message) }
  )

  let stringStore = Store(program: stringProgram)

#endif
