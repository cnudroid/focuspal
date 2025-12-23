//
//  ParentDashboardView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Parent controls dashboard with settings and management options.
struct ParentDashboardView: View {
    @StateObject private var viewModel = ParentDashboardViewModel()
    @State private var showingAuth = false

    var body: some View {
        NavigationStack {
            List {
                // Child profiles section
                Section("Child Profiles") {
                    ForEach(viewModel.children) { child in
                        ChildProfileRow(child: child)
                    }

                    Button {
                        viewModel.addChildTapped()
                    } label: {
                        Label("Add Child Profile", systemImage: "plus.circle")
                    }
                }

                // Time goals section
                Section("Time Goals") {
                    NavigationLink {
                        TimeGoalsView()
                    } label: {
                        Label("Manage Time Goals", systemImage: "target")
                    }
                }

                // Categories section
                Section("Categories") {
                    NavigationLink {
                        CategorySettingsView()
                    } label: {
                        Label("Manage Categories", systemImage: "folder")
                    }
                }

                // Reports section
                Section("Reports") {
                    NavigationLink {
                        ReportsView()
                    } label: {
                        Label("View Reports", systemImage: "chart.xyaxis.line")
                    }
                }

                // Settings section
                Section("Settings") {
                    NavigationLink {
                        // App settings view
                        Text("App Settings")
                    } label: {
                        Label("App Settings", systemImage: "gear")
                    }

                    NavigationLink {
                        // PIN management
                        Text("Change PIN")
                    } label: {
                        Label("Change PIN", systemImage: "lock")
                    }
                }
            }
            .navigationTitle("Parent Controls")
            .fullScreenCover(isPresented: $showingAuth) {
                AuthenticationView { success in
                    showingAuth = !success
                }
            }
            .onAppear {
                if !viewModel.isAuthenticated {
                    showingAuth = true
                }
            }
        }
    }
}

struct ChildProfileRow: View {
    let child: Child

    var body: some View {
        NavigationLink {
            // Child detail view
            Text("Child Settings for \(child.name)")
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(Color(hex: colorForTheme(child.themeColor)))

                VStack(alignment: .leading) {
                    Text(child.name)
                        .font(.headline)

                    Text("Age \(child.age)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func colorForTheme(_ theme: String) -> String {
        switch theme {
        case "pink": return "#FF69B4"
        case "blue": return "#4A90D9"
        case "green": return "#4CAF50"
        case "purple": return "#9C27B0"
        default: return "#888888"
        }
    }
}

#Preview {
    ParentDashboardView()
}
