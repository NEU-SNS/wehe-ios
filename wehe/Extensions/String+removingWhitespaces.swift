//
//  String+removingWhitespaces.swift
//  wehe
//
//  Created by Kirill Voloshin on 11/16/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import Foundation

extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }
}
