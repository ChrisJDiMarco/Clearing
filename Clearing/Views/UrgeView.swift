import SwiftUI

/// A quiet place to pause, take a real-world exit, and record what actually happened.
struct UrgeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var startWithPlan = false

    private enum Screen { case breathe, check, exit, okay, used }
    @State private var screen: Screen = .breathe
    @State private var started = false
    @State private var phase = "Breathe in"
    @State private var breathExpanded = false
    @State private var secondsLeft = 90
    @State private var selectedNeed = ""
    @State private var selectedAction = ""
    @State private var confirmUse = false
    @State private var breathingHaptics = BreathingHapticPulse()
    @State private var breathTask: Task<Void, Never>?

    private let countdown = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let needs = ["Unwind", "Sleep", "Numb out", "Reward", "Escape"]
    private let actions = ["Walk outside", "Drink water", "Text someone", "Shower", "Brush teeth"]
    private var suggestedAction: String {
        model.exitPlan?.action ?? (selectedAction.isEmpty ? "Change rooms for a minute" : selectedAction)
    }

    var body: some View {
        ZStack {
            Theme.indigo.ignoresSafeArea()
            switch screen {
            case .breathe: breathingView
            case .check: checkView
            case .exit: exitView
            case .okay: okayView
            case .used: usedView
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(countdown) { _ in
            guard screen == .breathe && started else { return }
            if secondsLeft > 1 {
                secondsLeft -= 1
            } else {
                secondsLeft = 0
                showCheck()
            }
        }
        .onAppear {
            model.logUrgeStart()
            if startWithPlan && model.exitPlan != nil { screen = .exit }
        }
        .onDisappear { stopBreathing() }
        .confirmationDialog("Record cannabis use today?", isPresented: $confirmUse) {
            Button("Record use") { record(.used) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This updates your current clear stretch. You can return to support whenever you want.")
        }
    }

    private var breathingView: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                Text("Just this\nmoment.")
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 43 : 54, weight: .regular, design: .serif))
                    .tracking(-2).lineSpacing(-6)
                    .foregroundStyle(Theme.paper)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(started ? phase : "Breathe with me")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(Theme.icyBlue.opacity(0.82))
                    .contentTransition(.opacity)
                    .padding(.top, 16)
                if let plan = model.exitPlan {
                    Button { showExit() } label: {
                        HStack(spacing: 13) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(Theme.icyBlue)
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.cue.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(Theme.icyBlue.opacity(0.8))
                                    .lineLimit(1)
                                Text(plan.action)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Theme.paper)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.icyBlue)
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.paper.opacity(0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.paper.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("Do my plan: \(plan.action)")
                    .padding(.top, 20)
                }
                CrystalArtView(name: "SupportCrystalHero")
                    .frame(height: dynamicTypeSize.isAccessibilitySize ? 140 : (model.exitPlan == nil ? 205 : 185))
                    .scaleEffect(reduceMotion || !started ? 1.15 : (breathExpanded ? 1.18 : 1.12))
                    .padding(.top, 4)
                    .accessibilityHidden(true)
                Text(String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60))
                    .font(.system(size: 55, weight: .ultraLight, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.icyBlue)
                    .padding(.top, -8)
                    .accessibilityLabel("\(secondsLeft) seconds remaining")
                if started {
                    ProgressView(value: Double(90 - secondsLeft), total: 90)
                        .tint(Theme.icyBlue)
                        .padding(.horizontal, 42)
                        .padding(.top, 8)
                }
                primaryButton(started ? "How is it now?" : "Start breathing") {
                    if started { showCheck() } else { startBreathing() }
                }
                .padding(.top, 23)
                if model.exitPlan == nil {
                    Button { showExit() } label: {
                        Text("Or take a small step now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.paper.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .padding(.top, 6)
                }
                supportShareLink.padding(.top, model.exitPlan == nil ? 2 : 8)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    private var checkView: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                CrystalArtView(name: "SupportCrystalHero")
                    .frame(height: 225)
                    .padding(.top, 12)
                    .accessibilityHidden(true)
                Text("How is it\nnow?")
                    .font(.system(size: 58, weight: .regular, design: .serif))
                    .tracking(-2).lineSpacing(-6)
                    .foregroundStyle(Theme.paper)
                    .multilineTextAlignment(.center)
                    .padding(.top, -10)
                Text("There is no right answer. Choose what is true.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.paper.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .padding(.top, 13)
                VStack(spacing: 10) {
                    choiceButton("I'm okay for now", icon: "checkmark") { record(.okay) }
                    choiceButton("I still want to use", icon: "arrow.turn.down.right") { record(.stillWant) }
                    choiceButton("I used", icon: "arrow.uturn.backward") { confirmUse = true }
                }
                .padding(.top, 34)
                Button { startBreathing() } label: {
                    Text("Breathe a little longer")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.paper.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .padding(.top, 5)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 35)
        }
        .scrollIndicators(.hidden)
    }

    private var exitView: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                Text("YOUR EXIT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(Theme.icyBlue)
                    .padding(.top, 24)
                Text("Change the\nscene.")
                    .font(.system(size: 58, weight: .regular, design: .serif))
                    .tracking(-2).lineSpacing(-6)
                    .foregroundStyle(Theme.paper)
                    .multilineTextAlignment(.center)
                    .padding(.top, 15)
                CrystalArtView(name: "SupportCrystalHero")
                    .frame(height: 208)
                    .padding(.top, 6)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 15) {
                    if let plan = model.exitPlan {
                        Text("WHEN THIS HAPPENS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(Theme.icyBlue.opacity(0.72))
                        Text(plan.cue)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.paper.opacity(0.72))
                    } else {
                        Text("ONE SMALL MOVE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(Theme.icyBlue.opacity(0.72))
                    }
                    HStack(alignment: .top, spacing: 13) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.icyBlue)
                            .frame(width: 24)
                            .padding(.top, 4)
                        Text(suggestedAction)
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Theme.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    Text(model.exitPlan == nil
                         ? "Try this before deciding what comes next."
                         : "Do the action you chose while you were calm. You can reassess afterward.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.paper.opacity(0.58))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(RoundedRectangle(cornerRadius: 24).fill(Theme.paper.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Theme.paper.opacity(0.14), lineWidth: 1))
                if model.exitPlan == nil {
                    VStack(alignment: .leading, spacing: 20) {
                        chipRow(title: "I want to", options: needs, selection: $selectedNeed)
                        chipRow(title: "I can", options: actions, selection: $selectedAction)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                }
                primaryButton("How is it now?") { showCheck() }
                    .padding(.top, 28)
                supportShareLink.padding(.top, 9)
                Button { startBreathing() } label: {
                    Text("Breathe with me instead")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.paper.opacity(0.58))
                        .padding(.vertical, 15)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
    }

    private var okayView: some View {
        closureView(title: "You made\nsome space.",
                    detail: "You said you're okay for now. You can take the next few minutes one step at a time.",
                    cardTitle: "KEEP IT SIMPLE",
                    cardBody: "If it helps, \(suggestedAction.lowercased()) next. You can come back whenever you need to.",
                    showSupport: false)
    }

    private var usedView: some View {
        closureView(title: "You can begin\nagain here.",
                    detail: "It's recorded. You don't owe this screen an explanation.",
                    cardTitle: "FOR THE NEXT HOUR",
                    cardBody: "Get somewhere comfortable, have some water, and reach out if you want company. One moment doesn't erase the care you've already put in.",
                    showSupport: true)
    }

    private func closureView(title: String, detail: String, cardTitle: String,
                             cardBody: String, showSupport: Bool) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                CrystalArtView(name: "SupportCrystalHero")
                    .frame(height: 238)
                    .padding(.top, 18)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 53, weight: .regular, design: .serif))
                    .tracking(-2).lineSpacing(-5)
                    .foregroundStyle(Theme.paper)
                    .multilineTextAlignment(.center)
                    .padding(.top, -8)
                Text(detail)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.paper.opacity(0.67))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 13)
                VStack(alignment: .leading, spacing: 11) {
                    Text(cardTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.icyBlue)
                    Text(cardBody)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.paper.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(21)
                .background(RoundedRectangle(cornerRadius: 22).fill(Theme.paper.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.paper.opacity(0.11), lineWidth: 1))
                .padding(.top, 33)
                primaryButton("Back to today") { dismiss() }
                    .padding(.top, 26)
                if showSupport { supportShareLink.padding(.top, 8) }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.paper)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .accessibilityLabel("Close support")
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 8)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 19)
            .background(Capsule().fill(Theme.icyBlue))
        }
        .buttonStyle(PressableStyle())
    }

    private func choiceButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.icyBlue)
                    .frame(width: 23)
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.paper)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.paper.opacity(0.55))
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 62)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.paper.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.paper.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private var supportShareLink: some View {
        ShareLink(item: model.exitPlan.map {
            "I'm having a craving. My plan is to \($0.action.lowercased()), but I could use some company. Can you check in with me?"
        } ?? "I'm having a craving and could use a little support. Can you check in with me?") {
            HStack(spacing: 9) {
                Image(systemName: "message")
                Text("Text someone")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Theme.paper.opacity(0.81))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private func chipRow(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Theme.paper.opacity(0.55))
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        Haptics.soft()
                        selection.wrappedValue = option
                    } label: {
                        Text(option)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selection.wrappedValue == option ? Theme.ink : Theme.paper)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 11)
                            .background(Capsule().fill(selection.wrappedValue == option ? Theme.icyBlue : Theme.paper.opacity(0.08)))
                            .overlay(Capsule().strokeBorder(Theme.paper.opacity(selection.wrappedValue == option ? 0 : 0.18), lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(selection.wrappedValue == option ? .isSelected : [])
                }
            }
        }
    }

    private func startBreathing() {
        Haptics.soft()
        stopBreathing()
        secondsLeft = 90
        phase = "Breathe in"
        breathExpanded = false
        withAnimation(.easeInOut(duration: 0.4)) {
            screen = .breathe
            started = true
        }
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 3.8)) { breathExpanded = true }
            breathingHaptics.start()
        }
        breathTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled && screen == .breathe else { break }
                withAnimation(.easeInOut(duration: 3.8)) {
                    phase = phase == "Breathe in" ? "Breathe out" : "Breathe in"
                    breathExpanded.toggle()
                }
            }
        }
    }

    private func stopBreathing() {
        breathTask?.cancel()
        breathTask = nil
        breathingHaptics.stop()
    }

    private func showCheck() {
        stopBreathing()
        Haptics.soft()
        withAnimation(.smooth) { screen = .check }
    }

    private func showExit() {
        stopBreathing()
        Haptics.soft()
        withAnimation(.smooth) { screen = .exit }
    }

    private func record(_ outcome: UrgeOutcome) {
        stopBreathing()
        // A suggestion or a saved plan is not evidence that the person did it.
        model.recordUrgeOutcome(outcome, need: selectedNeed, action: selectedAction)
        Haptics.soft()
        withAnimation(.smooth) {
            switch outcome {
            case .okay: screen = .okay
            case .stillWant: screen = .exit
            case .used: screen = .used
            }
        }
    }
}
