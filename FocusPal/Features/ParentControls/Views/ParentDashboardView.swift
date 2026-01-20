//
//  ParentDashboardView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Parent controls dashboard with settings and management options.
struct ParentDashboardView: View {
    @EnvironmentObject private var serviceContainer: ServiceContainer
    @StateObject private var viewModel = ParentDashboardViewModel()
    @State private var showingAuth = false

    var body: some View {
        NavigationStack {
            List {
                // Child profiles section
                Section("Child Profiles") {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                    } else if viewModel.children.isEmpty {
                        Text("No child profiles yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.children) { child in
                            ChildProfileRow(child: child)
                        }
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
                        ReportsView(serviceContainer: serviceContainer)
                    } label: {
                        Label("View Reports", systemImage: "chart.xyaxis.line")
                    }
                }

                // Activity section - Stats and Log moved from kid tabs
                Section("Activity") {
                    // Child selector for multi-child families
                    if viewModel.children.count > 1 {
                        Picker("View stats for", selection: $viewModel.selectedChildIndex) {
                            Text("All Children").tag(-1)
                            ForEach(Array(viewModel.children.enumerated()), id: \.offset) { index, child in
                                Text(child.name).tag(index)
                            }
                        }
                    }

                    NavigationLink {
                        if let child = viewModel.selectedChild {
                            StatisticsView(currentChild: child)
                        } else if let firstChild = viewModel.children.first {
                            StatisticsView(currentChild: firstChild)
                        } else {
                            Text("No child profiles found")
                        }
                    } label: {
                        Label("Statistics", systemImage: "chart.bar.fill")
                    }

                    NavigationLink {
                        if let child = viewModel.selectedChild {
                            ActivityLogView(currentChild: child)
                        } else if let firstChild = viewModel.children.first {
                            ActivityLogView(currentChild: firstChild)
                        } else {
                            Text("No child profiles found")
                        }
                    } label: {
                        Label("Activity Log", systemImage: "list.bullet.clipboard")
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
                        PINChangeView()
                    } label: {
                        Label("Change PIN", systemImage: "lock")
                    }
                }
            }
            .navigationTitle("Parent Controls")
            .fullScreenCover(isPresented: $showingAuth) {
                AuthenticationView {
                    showingAuth = false
                    viewModel.isAuthenticated = true
                }
            }
            .onAppear {
                if !viewModel.isAuthenticated {
                    showingAuth = true
                }
            }
            .task {
                await viewModel.loadChildren()
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
