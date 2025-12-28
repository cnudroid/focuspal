//
//  ParentProfilePromptView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View prompting existing users to set up their parent profile.
/// Shown as a sheet when parent accesses Parent Controls for the first time.
struct ParentProfilePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ParentProfilePromptViewModel()
    var onComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)

                        Text("Set Up Your Parent Profile")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("We'd love to keep you updated on your child's progress and achievements!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("Your Information") {
                    TextField("Parent Name", text: $viewModel.parentName)
                        .textContentType(.name)
                        .autocorrectionDisabled()

                    TextField("Email Address", text: $viewModel.parentEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    if !viewModel.parentEmail.isEmpty && !viewModel.isEmailValid() {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Please enter a valid email address")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Section {
                    Toggle(isOn: $viewModel.weeklyEmailEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Email Reports")
                                .font(.body)

                            Text("Receive a summary of your child's activities every week")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("You can change these preferences anytime in Parent Controls.")
                        .font(.caption)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.isSaved {
                                onComplete?()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Save Profile")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isLoading)

                    Button {
                        viewModel.skipForNow()
                        onComplete?()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Skip for Now")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Parent Profile")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(viewModel.isLoading)
        }
    }
}

#Preview {
    ParentProfilePromptView()
}
