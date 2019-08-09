//
//  Store.swift
//  WeeQOD
//
//  Created by Kevin O'Neill on 6/8/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Combine
import SwiftUI
import WeeDux

public final class Store<Environment, Model, Message>: ObservableObject {
  public final class Dispatcher: ObservableObject {
    private let program: Program<Environment, Model, Message>

    public func send(_ message: Message) {
      program.dispatch(message)
    }

    public func send(_ command: WeeDux.Command<Environment, Message>) {
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

  let stringProgram = Program<[String: Any], [String], String>(initial: ["Hello World"], environment: [:], handler: MessageHandler { state, message in state.append(message); return .none })
  let stringStore = Store(program: stringProgram)

#endif
