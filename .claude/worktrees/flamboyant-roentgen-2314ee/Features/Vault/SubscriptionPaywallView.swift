import SwiftUI

/// PRD — Pet Vault paywall. One-tap upgrade for unlimited storage, OCR,
/// expiry reminders, and travel paperwork.
struct SubscriptionPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = SubscriptionStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    hero
                    features
                    Spacer()
                    upgradeButton
                    restoreButton
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.xl)
            }
            .background(PawlyColors.cream.ignoresSafeArea())
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: Spacing.s) {
            ZStack {
                Circle()
                    .fill(PawlyColors.forest.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(PawlyColors.forest)
            }
            Text("Unlock the full Pet Vault")
                .font(PawlyFont.displayMedium)
                .foregroundStyle(PawlyColors.ink)
            Text("Keep every record safe, searchable, and ready for travel.")
                .font(PawlyFont.bodyMedium)
                .foregroundStyle(PawlyColors.slate)
                .multilineTextAlignment(.center)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            FeatureRow(symbol: "infinity", text: "Unlimited document storage")
            FeatureRow(symbol: "text.viewfinder", text: "OCR search across all documents")
            FeatureRow(symbol: "calendar.badge.clock", text: "Automatic expiry reminders")
            FeatureRow(symbol: "airplane", text: "Instant travel paperwork generation")
        }
    }

    private var upgradeButton: some View {
        Button {
            // V1: mock purchase. In production, wire StoreKit here.
            store.setPaid(true)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Upgrade — $4.99 / month")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pawlyPrimary)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            // V1: no-op. Production would call StoreKit restore.
        }
        .font(PawlyFont.caption)
        .foregroundStyle(PawlyColors.slate)
    }
}

private struct FeatureRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: symbol)
                .foregroundStyle(PawlyColors.forest)
                .frame(width: 32, height: 32)
                .background(Circle().fill(PawlyColors.forest.opacity(0.12)))
            Text(text)
                .font(PawlyFont.bodyLarge)
                .foregroundStyle(PawlyColors.ink)
            Spacer()
        }
    }
}
