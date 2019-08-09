//
//  Command.swift
//  WeeDux
//
//  Created by Kevin O'Neill on 11/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Dispatch
import Foundation

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
      let queue = DispatchQueue(label: "com.weegigs.command.combined.\(UUID().uuidString)", attributes: .concurrent)
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
