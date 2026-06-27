import SwiftUI

/// Hard onboarding paywall. Compliant: exact price, period, trial length, and a
/// working Restore. Closeable so the experience is never a dead end.
struct PaywallView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selected = Plans.annual
    @State private var appeared = false

    private let benefits: [(String, String)] = [
        ("lock.iphone", "Lock Screen & StandBy widgets — your streak, always in view"),
        ("bell.badge.fill", "Milestone reminders that land exactly when you need them"),
        ("books.vertical.fill", "The full recovery library — every fact, every stage"),
        ("paintpalette.fill", "Custom badge themes to show off your clean days"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x12382B), Color(hex: 0x060F0B)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                closeBar
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        benefitsList
                        planSelector
                        valueLine
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                ctaBlock
            }
        }
        .onAppear { withAnimation(.smooth(duration: 0.5)) { appeared = true } }
    }

    private var closeBar: some View {
        HStack {
            Spacer()
            Button { Haptics.soft(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.cream.opacity(0.5))
                    .padding(10)
                    .background(Circle().fill(.white.opacity(0.08)))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.glow(progress: 1)).frame(width: 140, height: 140)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(LinearGradient(colors: [Theme.gold, Theme.brightMint],
                                                    startPoint: .top, endPoint: .bottom))
                    .scaleEffect(appeared ? 1 : 0.8)
            }
            VStack(spacing: 6) {
                Text("Clearing Plus")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.gold)
                    .textCase(.uppercase)
                    .tracking(2)
                Text("Quit for good —\nbeautifully.")
                    .font(Theme.rounded(30, .bold))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 6)
    }

    private var benefitsList: some View {
        VStack(spacing: 14) {
            ForEach(benefits, id: \.0) { item in
                HStack(spacing: 14) {
                    Image(systemName: item.0)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.mint)
                        .frame(width: 30)
                    Text(item.1)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.cream.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planSelector: some View {
        VStack(spacing: 10) {
            ForEach(Plans.all) { plan in
                PlanRow(plan: plan, priceLabel: store.displayPrice(for: plan), selected: selected.id == plan.id) {
                    Haptics.soft()
                    selected = plan
                }
            }
        }
    }

    private var valueLine: some View {
        Text("Your money-saved counter usually covers it within the first two weeks.")
            .font(Theme.rounded(13))
            .foregroundStyle(Theme.cream.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
    }

    private var ctaBlock: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await store.purchase(selected)
                    if store.isPremium { dismiss() }
                }
            } label: {
                Group {
                    if store.isPurchasing {
                        ProgressView().tint(Color(hex: 0x06241A))
                    } else {
                        Text(ctaTitle).font(Theme.rounded(18, .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .foregroundStyle(Color(hex: 0x06241A))
                .background(Capsule().fill(
                    LinearGradient(colors: [Theme.brightMint, Theme.mint],
                                   startPoint: .leading, endPoint: .trailing)))
            }
            .buttonStyle(PressableStyle())
            .disabled(store.isPurchasing)

            Text(finePrint)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.cream.opacity(0.4))
                .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                Button("Restore") { Task { await store.restore() } }
                Text("·").foregroundStyle(Theme.cream.opacity(0.3))
                Button("Terms") {}
                Text("·").foregroundStyle(Theme.cream.opacity(0.3))
                Button("Privacy") {}
            }
            .font(Theme.rounded(12, .medium))
            .foregroundStyle(Theme.cream.opacity(0.5))
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial.opacity(0.6))
    }

    private var ctaTitle: String {
        if let trial = selected.trialLabel { return "Start \(trial)" }
        return "Continue — \(store.displayPrice(for: selected))"
    }

    private var finePrint: String {
        let price = store.displayPrice(for: selected)
        switch selected.id {
        case "annual":
            return "Free for 7 days, then \(price)/year. Auto-renews until cancelled. Cancel anytime in Settings."
        case "lifetime":
            return "One-time payment of \(price). No subscription."
        default:
            return "\(price)/month. Auto-renews until cancelled. Cancel anytime in Settings."
        }
    }
}

private struct PlanRow: View {
    let plan: Plan
    let priceLabel: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(selected ? Theme.mint : Theme.cream.opacity(0.25), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if selected {
                        Circle().fill(Theme.mint).frame(width: 14, height: 14)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.cream)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(Theme.rounded(10, .bold))
                                .foregroundStyle(Color(hex: 0x06241A))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Theme.gold))
                        }
                    }
                    if let sub = plan.subLabel {
                        Text(sub).font(Theme.rounded(13)).foregroundStyle(Theme.cream.opacity(0.55))
                    } else if let trial = plan.trialLabel {
                        Text(trial).font(Theme.rounded(13)).foregroundStyle(Theme.mint)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(priceLabel).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.cream)
                    Text(plan.periodLabel).font(Theme.rounded(11)).foregroundStyle(Theme.cream.opacity(0.5))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(selected ? 0.10 : 0.04))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(selected ? Theme.mint : .white.opacity(0.08),
                                lineWidth: selected ? 1.8 : 1))
            )
        }
        .buttonStyle(PressableStyle())
    }
}
