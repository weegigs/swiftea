//
//  Created by Kevin O'Neill on 4/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

import Foundation

func noop() {}

func noop<T>(value _: T) {}

func noop<T>() -> T? { return nil }

func noop<T, S>(value _: T) -> S? { return nil }
