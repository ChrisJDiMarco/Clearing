import SwiftUI

/// Holds the tab content, the floating tab bar, and one full-screen support
/// or milestone experience at a time.
struct MainView: View {
    @Environment(AppModel.self) private var model

    @State private var tab: Tab = .home
    @State private var showSettings = false
    @State private var cover: ActiveCover?

    enum Tab { case home, progress }

    /// One cover state avoids stacking multiple `.fullScreenCover` modifiers.
    enum ActiveCover: Identifiable {
        case urge
        case exitPlan
        case celebration(Milestone)
        var id: String {
            switch self {
            case .urge: "urge"
            case .exitPlan: "exitPlan"
            case .celebration(let m): "m\(m.day)"
            }
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground(progress: model.dawnProgress())

            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .home:     HomeView(showSettings: $showSettings,
                                             onDebugCelebrate: presentPendingCelebration,
                                             onSupport: { cover = .urge },
                                             onUsePlan: { cover = .exitPlan })
                    case .progress: RecoveryTimelineView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(alignment: .bottom) { tabBoundaryFade }

                tabBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $cover) { which in
            switch which {
            case .urge:
                UrgeView()
            case .exitPlan:
                UrgeView(startWithPlan: true)
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
            case "urge":      cover = .urge
            case "milestone": if let m = model.reachedMilestones().last { cover = .celebration(m) }
            case "settings":  showSettings = true
            default: break
            }
            #endif
            checkCelebration()
            if model.data.remindersEnabled {
                Task {
                    let granted = await Reminders.requestAuthorization()
                    if !granted { model.data.remindersEnabled = false }
                    model.refreshReminders()
                }
            }
        }
    }

    private var tabBoundaryFade: some View {
        LinearGradient(colors: [.clear, Theme.canvas.opacity(0.96)],
                       startPoint: .top, endPoint: .bottom)
            .frame(height: 36)
            .allowsHitTesting(false)
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

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabItem(.home, icon: "house.fill", label: "Today")
            tabItem(.progress, icon: "chart.bar.fill", label: "Progress")
            urgeButton
        }
        .padding(.horizontal, 26)
        .padding(.top, 9)
        .padding(.bottom, 4)
        .background {
            Theme.paper
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) { Theme.hairline.frame(height: 1) }
        }
    }

    private func tabItem(_ which: Tab, icon: String, label: String) -> some View {
        Button {
            Haptics.soft()
            withAnimation(.snappy) { tab = which }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 20, weight: .medium))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(tab == which ? Theme.ink : Theme.mutedInk)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
    }

    private var urgeButton: some View {
        Button {
            Haptics.rigid()
            cover = .urge
        } label: {
            VStack(spacing: 5) {
                Image(systemName: "lifepreserver").font(.system(size: 20, weight: .medium))
                Text("Support").font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Theme.mutedInk)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(PressableStyle())
    }
}
