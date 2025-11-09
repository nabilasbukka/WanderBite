import SwiftUI

struct SafetyBadge: View {
    let status: SafetyStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
                .font(.caption.bold())
            Text(status.rawValue)
                .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .foregroundStyle(.white)
        .background(status.color.gradient)
        .clipShape(Capsule())
        .accessibilityLabel("Safety status: \(status.rawValue)")
    }
}

#Preview {
    VStack(spacing: 12) {
        SafetyBadge(status: .strictSafe)
        SafetyBadge(status: .safe)
        SafetyBadge(status: .checkDetails)
    }
    .padding()
    .background(Color(.systemBackground))
}