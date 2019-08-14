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


/// Commands coordinate between the `Program` and the outside world.
///
/// Though it's tempting to have commands take action directly, e.g. load an image, they should depend on
/// services to do the actual work. This keeps the `Command` squarely in the role of coordinator, making
/// them easy to test.
///
/// ```
/// enum CategoriesCommands {
///   static let refreshCategories = CategoriesCommand { environment, publish in
///
///     let task = environment.quotes.categories { result in
///       switch result {
///       case let .failure(error):
///         publish(CategoriesMessage.categoriesLoadingFailed(error: error))
///       case let .success(categories):
///         publish(CategoriesMessage.categoriesLoaded(categories: categories))
///       }
///     }
///     publish(CategoriesMessage.categoriesLoading(task: task))
///   }
/// }
/// ```
///
public struct Command<Environment, Message> {
  
  /// A closure to run when the command is executed
  ///
  /// An `Effect` is used to interact with the services provided in the `Environment` and publish
  /// messages back to the program
  ///
  /// ```
  /// enum CategoriesCommands {
  ///   static let refreshCategories = CategoriesCommand { environment, publish in
  ///
  ///     let task = environment.quotes.categories { result in
  ///       switch result {
  ///       case let .failure(error):
  ///         publish(CategoriesMessage.categoriesLoadingFailed(error: error))
  ///       case let .success(categories):
  ///         publish(CategoriesMessage.categoriesLoaded(categories: categories))
  ///       }
  ///     }
  ///     publish(CategoriesMessage.categoriesLoading(task: task))
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - environment: The `Environment` containing the services the `Command` depends on
  ///   - publish: A method to send messages to the program
  ///
  public typealias Effect = (_ environment: Environment, _ publish: @escaping (Message) -> Void) -> Void
  
  /// The `Effect` to be run in the `Environment`
  public let run: Effect

  /// - Parameters:
  ///   - effect: the closure to run when the command is executed
  ///
  public init(effect: @escaping Effect) {
    run = effect
  }
}

public extension Command {
  
  /// A `Command` that has no effect
  static var none: Command<Environment, Message> {
    return Command { _, _ in }
  }

  /// Batches an array of commands into a single `Command`
  ///
  /// Execution order is arbitary and the commands are run in parallel
  ///
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

/// Combines to Commands
public func <> <Message, Environment>(
  _ first: Command<Environment, Message>,
  _ second: Command<Environment, Message>
) -> Command<Environment, Message> {
  return Command<Environment, Message>.batch([first, second])
}


public extension Command {
  
  /// Lifts a command into a higher context
  ///
  /// A `fatalError()` is generated when the `Command` is run if either of the
  /// requirements are not met.
  ///
  /// - Requires:
  ///   - `E` conforms to `Environment`
  ///   - `Message` conforms to `M`
  ///
  func lift<E, M>() -> Command<E, M> {
    return Command<E, M>(effect: { environment, publish in
      guard let environment = environment as? Environment else {
        fatalError("environment \(type(of: E.self)) cant be converted to \(Environment.self)")
      }
      
      let send = { (message: Message) -> Void in
        guard let message = message as? M else {
          fatalError("message \(type(of: Message.self)) cant be converted to \(M.self)")
        }
        
        publish(message)
      }
      
      self.run(environment, send)
    })
  }
}
