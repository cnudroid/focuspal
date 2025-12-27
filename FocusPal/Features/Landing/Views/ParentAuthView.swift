//
//  ParentAuthView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Wrapper view for parent PIN authentication with cancel option.
struct ParentAuthView: View {
    let onAuthenticated: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            PINEntryView(onAuthenticated: onAuthenticated)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                }
        }
    }
}

#Preview {
    ParentAuthView(onAuthenticated: {}, onCancel: {})
}
