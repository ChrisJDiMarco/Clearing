import SwiftUI

/// Holds the tab content, the floating tab bar, and a single full-screen cover
/// (paywall OR milestone celebration — never both at once).
struct MainView: View {
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store

    @State private var tab: Tab = .home
    @State private var showUrge = false
    @State private var showSettings = false
    @State private var cover: ActiveCover?

    enum Tab { case home, progress }

    /// One cover state avoids stacking two `.fullScreenCover` modifiers (undefined order).
    enum ActiveCover: Identifiable {
        case paywall
        case celebration(Milestone)
        var id: String {
            switch self {
            case .paywall: "paywall"
            case .celebration(let m): "m\(m.day)"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:     HomeView(showSettings: $showSettings, onDebugCelebrate: presentPendingCelebration)
                case .progress: RecoveryTimelineView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .sheet(isPresented: $showUrge) {
            UrgeView().presentationDetents([.large])
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $cover) { which in
            switch which {
            case .paywall:
                PaywallView()
            case .celebration(let milestone):
                MilestoneCelebrationView(milestone: milestone) {
                    model.markCelebrated(milestone)
                    cover = nil
                }
            }
        }
        .onAppear {
            #if DEBUG
            switch Demo.screen {
            case "progress": tab = .progress
            case "urge":      showUrge = true
            case "milestone": if let m = model.reachedMilestones().last { cover = .celebration(m) }
            case "paywall":   presentPaywall()
            case "settings":  showSettings = true
            default: break
            }
            #endif
            checkCelebration()
            maybePresentPaywall()
            if model.data.remindersEnabled {
                Task {
                    let granted = await Reminders.requestAuthorization()
                    if !granted { model.data.remindersEnabled = false }
                    model.refreshReminders()
                }
            }
        }
    }

    private func checkCelebration() {
        if cover == nil, let pending = model.pendingCelebration() {
            cover = .celebration(pending)
        }
    }

    private func presentPendingCelebration() {
        if cover == nil, let pending = model.pendingCelebration() {
            cover = .celebration(pending)
        }
    }

    /// Hard onboarding paywall: shown once after onboarding, if not already premium.
    private func maybePresentPaywall() {
        guard cover == nil else { return }
        if !store.isPremium && !model.data.hasSeenPaywall {
            presentPaywall()
        }
    }

    private func presentPaywall() {
        model.data.hasSeenPaywall = true   // mark at present-time, not on dismiss (avoids re-show race)
        cover = .paywall
    }

    private var tabBar: some View {
        HStack(spacing: 10) {
            tabItem(.home, icon: "house.fill", label: "Today")
            urgeButton
            tabItem(.progress, icon: "chart.line.uptrend.xyaxis", label: "Progress")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                   startPoint: .top, endPoint: .bottom), lineWidth: 1))
                .softShadow(.black.opacity(0.4), radius: 20, y: 12)
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 6)
    }

    private func tabItem(_ which: Tab, icon: String, label: String) -> some View {
        Button {
            Haptics.soft()
            withAnimation(.snappy) { tab = which }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(label).font(Theme.rounded(10, .semibold))
            }
            .foregroundStyle(tab == which ? Theme.mint : Theme.cream.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var urgeButton: some View {
        Button {
            Haptics.rigid()
            showUrge = true
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "wind").font(.system(size: 20, weight: .bold))
                Text("Urge").font(Theme.rounded(10, .bold))
            }
            .foregroundStyle(Color(hex: 0x06241A))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [Theme.brightMint, Theme.mint],
                                   startPoint: .top, endPoint: .bottom))
            )
        }
        .buttonStyle(PressableStyle())
    }
}
