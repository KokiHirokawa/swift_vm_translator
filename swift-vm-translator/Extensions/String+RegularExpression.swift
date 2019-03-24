//
//  String+RegularExpression.swift
//  swift-vm-translator
//
//  Created by KokiHirokawa on 2019/03/24.
//  Copyright © 2019 KokiHirokawa. All rights reserved.
//

import Foundation

extension String {
    
    func isMatch(pattern: String) -> Bool {
        guard let regExp = try? NSRegularExpression(pattern: pattern) else { return false }
        let count = regExp.numberOfMatches(in: self, range: NSMakeRange(0, self.count))
        return count != 0
    }
    
    func firstMatch(pattern: String) -> NSTextCheckingResult? {
        guard let regExp = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matche = regExp.firstMatch(in: self, range: NSMakeRange(0, self.count))
        return matche
    }
}
