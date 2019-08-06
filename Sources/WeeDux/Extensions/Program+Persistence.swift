//
//  Program+Persistence.swift
//
//
//  Created by Kevin O'Neill on 24/7/19.
//

import Dispatch
import Foundation

private let queue = DispatchQueue(label: "au.id.oneill.weedux.persistence", qos: .background)

private func _write<State: Codable>(state: State, to destination: URL) {
  guard destination.isFileURL else {
    fatalError("stored location must be a file url")
  }

  queue.async {
    do {
      let data = try JSONEncoder().encode(state)
      try data.write(to: destination)
    } catch {
      print(error)
    }
  }
}

public extension Program where State: Codable {
  convenience init(from: URL = defaultFile(), initial: State, environment: Environment, middleware: [Middleware<Environment, State, Message>] = [], handler: MessageHandler<Environment, State, Message>) {
    guard from.isFileURL else {
      fatalError("stored location must be a file url")
    }

    let persistence: Middleware<Environment, State, Message> = { _, state, next in { message in
      next(message)
      _write(state: state(), to: from)
    } }
    let persisted = middleware + [persistence]

    #if DEBUG
      if CommandLine.arguments.contains("--reset") {
        self.init(state: initial, environment: environment, middleware: persisted, handler: handler)
        return
      }
    #endif

    do {
      let data = try Data(contentsOf: from)

      let state = try JSONDecoder().decode(State.self, from: data)
      self.init(state: state, environment: environment, middleware: persisted, handler: handler)

    } catch {
      self.init(state: initial, environment: environment, middleware: persisted, handler: handler)
    }
  }

  func write(to destination: URL = defaultFile()) throws {
    _write(state: read(), to: destination)
  }

  static func defaultFile() -> URL {
    let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    return library.appendingPathComponent("weedux-storage.json").standardizedFileURL
  }
}
