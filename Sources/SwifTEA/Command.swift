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

import Dispatch
import Foundation

private let queue = DispatchQueue(label: "com.weegigs.swiftea.command.batch", attributes: .concurrent)

public struct Command<Environment, Message> {
  public typealias Effect = (Environment, @escaping (Message) -> Void) -> Void
  public let run: Effect

  public init(effect: @escaping Effect) {
    run = effect
  }
}

public extension Command {
  static var none: Command<Environment, Message> {
    return Command { _, _ in }
  }

  /**
   * Batching makes no guarentees about execution order
   */
  static func batch<Environment, Message>(
    _ commands: [Command<Environment, Message>]
  ) -> Command<Environment, Message> {
    return Command<Environment, Message> { environment, projection in
      for command in commands {
        queue.async {
          command.run(environment, projection)
        }
      }
    }
  }
}

public func <> <Message, Environment>(
  _ first: Command<Environment, Message>,
  _ second: Command<Environment, Message>
) -> Command<Environment, Message> {
  return Command<Environment, Message>.batch([first, second])
}
