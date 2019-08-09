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

import SwiftUI

public struct StateContainer<Environment, State, Message, Props, Content>: View where Content: View {
  public typealias Dispatcher = Store<Environment, State, Message>.Dispatcher

  @EnvironmentObject private var store: Store<Environment, State, Message>
  @EnvironmentObject private var dispatcher: Dispatcher

  private let render: (Props, Dispatcher) -> Content
  private let read: (State) -> Props

  public init(read: @escaping (State) -> Props, render: @escaping (Props, Dispatcher) -> Content) {
    self.read = read
    self.render = render
  }

  public var body: some View {
    render(read(store.model), dispatcher)
  }
}

public extension StateContainer {
  init(_ keypath: KeyPath<State, Props>, render: @escaping (Props, Dispatcher) -> Content) {
    self.init(read: { $0[keyPath: keypath] }, render: render)
  }

  init<A, B>(_ a: KeyPath<State, A>, _ b: KeyPath<State, B>, render: @escaping ((A, B), Dispatcher) -> Content) where Props == (A, B) {
    self.init(read: { ($0[keyPath: a], $0[keyPath: b]) }, render: render)
  }

  init<A, B, C>(_ a: KeyPath<State, A>, _ b: KeyPath<State, B>, _ c: KeyPath<State, C>, render: @escaping ((A, B, C), Dispatcher) -> Content) where Props == (A, B, C) {
    self.init(read: { ($0[keyPath: a], $0[keyPath: b], $0[keyPath: c]) }, render: render)
  }

  init<A, B, C, D>(_ a: KeyPath<State, A>, _ b: KeyPath<State, B>, _ c: KeyPath<State, C>, _ d: KeyPath<State, D>, render: @escaping ((A, B, C, D), Dispatcher) -> Content) where Props == (A, B, C, D) {
    self.init(read: { ($0[keyPath: a], $0[keyPath: b], $0[keyPath: c], $0[keyPath: d]) }, render: render)
  }
}

#if DEBUG
  typealias StringStateContainer<Props, Content> = StateContainer<[String: Any], [String], String, Props, Content> where Content: View

  struct StateContainer_Previews: PreviewProvider {
    static var previews: some View {
      StoreContainer(for: stringStore) {
        StringStateContainer(\.self) { items, _ in
          List {
            ForEach(items, id: \.self) {
              Text($0)
            }
          }
        }
      }
    }
  }
#endif
