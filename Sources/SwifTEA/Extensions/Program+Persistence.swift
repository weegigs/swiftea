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

private let queue = DispatchQueue(label: "au.id.oneill.swiftea.persistence", qos: .background)

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
    return library.appendingPathComponent("swiftea-storage.json").standardizedFileURL
  }
}
