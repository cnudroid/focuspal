//
//  PINService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import Security

/// Errors that can occur during PIN operations
enum PINServiceError: Error, Equatable {
    case invalidPinLength
    case invalidPinFormat
    case keychainError(status: OSStatus)
}

/// Service for securely storing and verifying parent PIN using Keychain
final class PINService {

    // MARK: - Properties

    private let keychainService = "com.focuspal.parent.pin"
    private let keychainAccount = "parentPin"

    // MARK: - Public Methods

    /// Check if a PIN has been set
    /// - Returns: true if PIN exists in Keychain, false otherwise
    func isPinSet() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Save a PIN to Keychain
    /// - Parameter pin: The 4-digit PIN to save
    /// - Throws: PINServiceError if PIN is invalid or Keychain operation fails
    func savePin(pin: String) throws {
        // Validate PIN length
        guard pin.count == 4 else {
            throw PINServiceError.invalidPinLength
        }

        // Validate PIN format (must be numeric)
        guard pin.allSatisfy({ $0.isNumber }) else {
            throw PINServiceError.invalidPinFormat
        }

        // Convert PIN to Data
        guard let pinData = pin.data(using: .utf8) else {
            throw PINServiceError.keychainError(status: errSecParam)
        }

        // Delete existing PIN if present
        deletePin()

        // Add new PIN to Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: pinData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw PINServiceError.keychainError(status: status)
        }
    }

    /// Verify a PIN against the stored PIN
    /// - Parameter pin: The PIN to verify
    /// - Returns: true if PIN matches, false otherwise
    func verifyPin(pin: String) -> Bool {
        // Query Keychain for stored PIN
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let storedPin = String(data: data, encoding: .utf8) else {
            return false
        }

        return storedPin == pin
    }

    /// Reset (delete) the stored PIN
    func resetPin() {
        deletePin()
    }

    // MARK: - Private Methods

    private func deletePin() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
    }
}
