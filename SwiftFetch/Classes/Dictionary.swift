//
//  Dictionary.swift
//  SwiftFetch
//
//  Created by Yury Dymov on 3/29/17.
//  Copyright © 2017 Yury Dymov. All rights reserved.
//

extension Dictionary {
    @discardableResult
    mutating func merge(_ other: Dictionary?) -> Dictionary {
        for (key, value) in other ?? [:] {
            self.updateValue(value, forKey: key)
        }
        
        return self
    }
    
    func extend(_ other: Dictionary?) -> Dictionary {
        var ret = self
        
        for (key, value) in other ?? [:] {
            ret.updateValue(value, forKey: key)
        }
        
        return ret
    }
}

