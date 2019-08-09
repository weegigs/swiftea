//
//  StoreContainer.swift
//  WeeQOD
//
//  Created by Kevin O'Neill on 6/8/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import SwiftUI
import WeeDux

struct StoreContainer<Environment, State, Message, Content>: View where Content: View {
  @ObservedObject private var store: Store<Environment, State, Message>

  private let content: () -> Content

  var body: some View {
    content()
      .environmentObject(self.store)
      .environmentObject(self.store.dispatcher)
  }

  init(for store: Store<Environment, State, Message>, content: @escaping () -> Content) {
    self.store = store
    self.content = content
  }
}

#if DEBUG

  struct StoreContainer_Previews: PreviewProvider {
    static var previews: some View {
      StoreContainer(for: stringStore) {
        Text("A")
      }
    }
  }
#endif
