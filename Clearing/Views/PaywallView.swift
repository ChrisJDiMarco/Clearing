import SwiftUI

/// Kept for existing purchases and future Plus work. There is no purchase
/// entry point until Plus offers a real, entitlement-backed benefit.
struct PaywallView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AmbientBackground(progress: 0.4)

            VStack(spacing: 22) {
                Spacer()

                ZStack {
                    Circle().fill(Theme.glow(progress: 1))
                        .frame(width: 140, height: 140)
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 50, weight: .ultraLight))
                        .foregroundStyle(LinearGradient(
                            colors: [Theme.amber, Theme.amberLight, Theme.icyBlue],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                }

                Text("All the space you need.")
                    .font(Theme.display(38))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text("Clearing’s core tools are available without a subscription. We’ll only offer Plus when it adds something genuinely useful.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.mutedInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Continue to Clearing") { dismiss() }
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(Theme.ink))
                    .buttonStyle(PressableStyle())

                Button("Restore a previous purchase") {
                    Task { await store.restore() }
                }
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.mutedInk)
                .disabled(store.isPurchasing)
            }
            .padding(28)
        }
    }
}
