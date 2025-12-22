//
//  ParentDashboardViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation

/// ViewModel for the Parent Dashboard.
@MainActor
class ParentDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var children: [Child] = []
    @Published var isAuthenticated = false
    @Published var isLoading = false

    // MARK: - Initialization

    init() {
        loadChildren()
    }

    // MARK: - Public Methods

    func loadChildren() {
        // Mock data
        children = [
            Child(name: "Emma", age: 8, themeColor: "pink"),
            Child(name: "Lucas", age: 10, themeColor: "blue")
        ]
    }

    func addChildTapped() {
        // Navigate to add child flow
    }

    func authenticate() {
        isAuthenticated = true
    }
}
