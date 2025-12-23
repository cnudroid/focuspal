//
//  PINServiceProtocol.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// Protocol for PIN service to enable testing
protocol PINServiceProtocol {
    func isPinSet() -> Bool
    func savePin(pin: String) throws
    func verifyPin(pin: String) -> Bool
    func resetPin()
}

// Make PINService conform to the protocol
extension PINService: PINServiceProtocol {}
