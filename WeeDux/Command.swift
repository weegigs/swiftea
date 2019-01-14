//
//  Command.swift
//  WeeDux
//
//  Created by Kevin O'Neill on 11/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Dispatch

public struct Command<Environment, Event> {
  public typealias Effect = (Environment, @escaping (Event) -> Void) -> Void
  public let run: Effect

  public init(effect: @escaping Effect) {
    run = effect
  }
}

public extension Command {
  public static var none: Command<Environment, Event> {
    return Command { _, _ in }
  }

  /**
   * Batching makes no guarentees about execution order
   */
  static func batch<Environment, Event>(
    _ commands: [Command<Environment, Event>]
  ) -> Command<Environment, Event> {
    return Command<Environment, Event> { environment, projection in
      let queue = DispatchQueue(label: "com.weegigs.command.combined.\(UUID().uuidString)", attributes: .concurrent)
      for command in commands {
        queue.async {
          command.run(environment, projection)
        }
      }
    }
  }
}

public func <> <Event, Environment>(
  _ first: Command<Environment, Event>,
  _ second: Command<Environment, Event>
) -> Command<Environment, Event> {
  return Command<Environment, Event>.batch([first, second])
}
