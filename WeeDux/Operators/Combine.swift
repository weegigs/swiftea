//
//  Created by Kevin O'Neill on 6/1/19.
//  Copyright © 2019 Kevin O'Neill. All rights reserved.
//

precedencegroup CombinePrecedence {
  associativity: left
  higherThan: AssignmentPrecedence
}

infix operator <>: CombinePrecedence
