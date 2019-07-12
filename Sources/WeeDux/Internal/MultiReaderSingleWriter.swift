//
//  Created by Kevin O'Neill on 9/11/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Foundation

class MultiReaderSingleWriter<T> {
  private let lock = DispatchQueue(label: "com.weegigs.mrsw.\(UUID().uuidString)", attributes: .concurrent)
  private var _value: T

  public var value: T {
    get {
      var value: T?
      lock.sync {
        value = self._value
      }
      return value!
    }
    set {
      update { value in value = newValue }
    }
  }

  public init(_ value: T) {
    _value = value
  }

  public func update(updater: (inout T) -> Void) {
    lock.sync(flags: .barrier) {
      updater(&self._value)
    }
  }
}
