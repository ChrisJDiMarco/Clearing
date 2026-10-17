import SwiftUI

@main
struct ClearingApp: App {
    @State private var model = AppModel()
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(store)
                .preferredColorScheme(.light)
                .tint(Theme.mint)
        }
    }
}

/// Routes between onboarding and the main experience.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if model.data.hasOnboarded {
                MainView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.5), value: model.data.hasOnboarded)
    }
}
