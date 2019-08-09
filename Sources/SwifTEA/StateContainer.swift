//
//  StateContainer.swift
//  WeeQOD
//
//  Created by Kevin O'Neill on 6/8/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import SwiftUI

struct StateContainer<Environment, State, Message, Props, Content>: View where Content: View {
  typealias Dispatcher = Store<Environment, State, Message>.Dispatcher

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

extension StateContainer {
  public init(_ keypath: KeyPath<State, Props>, render: @escaping (Props, Dispatcher) -> Content) {
    self.init(read: { $0[keyPath: keypath] }, render: render)
  }

  public init<A, B>(_ a: KeyPath<State, A>, _ b: KeyPath<State, B>, render: @escaping ((A, B), Dispatcher) -> Content) where Props == (A, B) {
    self.init(read: { ($0[keyPath: a], $0[keyPath: b]) }, render: render)
  }

  public init<A, B, C>(_ a: KeyPath<State, A>, _ b: KeyPath<State, B>, _ c: KeyPath<State, C>, render: @escaping ((A, B, C), Dispatcher) -> Content) where Props == (A, B, C) {
    self.init(read: { ($0[keyPath: a], $0[keyPath: b], $0[keyPath: c]) }, render: render)
  }

  public init<A, B, C, D>(_ a: KeyPath<State, A>, _ b: KeyPath<State, B>, _ c: KeyPath<State, C>, _ d: KeyPath<State, D>, render: @escaping ((A, B, C, D), Dispatcher) -> Content) where Props == (A, B, C, D) {
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
