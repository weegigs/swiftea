//
//  Created by Kevin O'Neill on 24/12/18.
//  Copyright © 2018 Kevin O'Neill. All rights reserved.
//

import Foundation

public typealias Reducer<State, EventSet> = (State, EventSet) -> State

func combineReducers<State, EventSet>(reducers: [Reducer<State, EventSet>]) -> Reducer<State, EventSet> {
  return { (state: State, command: EventSet) in
    reducers.reduce(state, { state, reducer in reducer(state, command) })
  }
}

public func combineReducers<State, EventSet>(
  _ first: @escaping Reducer<State, EventSet>,
  _ second: @escaping Reducer<State, EventSet>,
  _ rest: Reducer<State, EventSet>...
) -> Reducer<State, EventSet> {
  return combineReducers(reducers: [first, second] + rest)
}

public func <> <State, EventSet>(
  _ first: @escaping Reducer<State, EventSet>,
  _ second: @escaping Reducer<State, EventSet>
) -> Reducer<State, EventSet> {
  return combineReducers(reducers: [first, second])
}
