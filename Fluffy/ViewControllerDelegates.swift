//
//  VCDelegates.swift
//  Fluffy
//
//  Created by Suolapeikko on 20/11/2017.
//  Copyright © 2018 Antti Tulisalo. All rights reserved.
//

import Foundation
import GSS

protocol StatusDelegate: class {
    func updateAuthenticationStatus(principal: String, authStatus: Bool)
    func authenticationStatus() -> Bool
    func startTimer()
    func stopTimer()
    func refreshTGT() -> Bool
}
