//
//  CharacterSet.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 17/09/1447 AH.
//

import Foundation

extension CharacterSet {
    static let alphaDash = CharacterSet
        .alphanumerics
        .union(CharacterSet(charactersIn: "-_"))
}
