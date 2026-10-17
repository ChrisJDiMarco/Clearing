import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(progress: 0.1)

                ScrollView {
                    VStack(spacing: 16) {
                        calibrationCard
                        statsCard
                        remindersCard
                        disclaimerCard
                        Button("Restore previous purchase") {
                            Task { await store.restore() }
                        }
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.mutedInk)
                        .disabled(store.isPurchasing)
                        resetButton
                        footer
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.ink)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .confirmationDialog("Reset everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset all progress", role: .destructive) {
                model.resetAll()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your streak, milestones, and saved totals. It can't be undone.")
        }
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            settingRow("Current stretch since", value: model.cleanStart.formatted(date: .abbreviated, time: .omitted))
            Divider().overlay(Theme.hairline)
            settingRow("Weekly cost", value: model.data.weeklySpend.asMoney)
            Divider().overlay(Theme.hairline)
            settingRow("Hard moments handled", value: "\(model.urgesBeaten)")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .background(GlassCard())
    }

    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Plan calibration", systemImage: "slider.horizontal.3")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.cream)

            VStack(alignment: .leading, spacing: 10) {
                settingLabel("Risk window")
                FlowLayout(spacing: 8) {
                    ForEach(RiskWindow.allCases) { window in
                        Button {
                            Haptics.soft()
                            model.data.riskWindow = window.rawValue
                            model.refreshReminders()
                        } label: {
                            Chip(title: window.shortLabel, icon: window.icon,
                                 selected: model.selectedRiskWindow() == window)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    settingLabel("Weekly cost")
                    Spacer()
                    Text(model.data.weeklySpend.asMoney)
                        .font(Theme.rounded(14, .bold))
                        .foregroundStyle(Theme.amberInk)
                }
                Slider(value: Binding(get: {
                    model.data.weeklySpend
                }, set: { value in
                    model.data.weeklySpend = value
                }), in: 0...300, step: 5)
                .tint(Theme.mint)
            }

            Stepper(value: Binding(get: {
                model.data.sessionsPerDay
            }, set: { value in
                model.data.sessionsPerDay = value
            }), in: 0...20, step: 0.5) {
                HStack {
                    settingLabel("Daily sessions")
                    Spacer()
                    Text(String(format: "%.1f", model.data.sessionsPerDay))
                        .font(Theme.rounded(14, .bold))
                        .foregroundStyle(Theme.cream)
                }
            }
            .tint(Theme.mint)

            VStack(alignment: .leading, spacing: 10) {
                settingLabel("Reasons")
                FlowLayout(spacing: 8) {
                    ForEach(Reason.allCases) { reason in
                        let selected = model.data.reasons.contains(reason.rawValue)
                        Button {
                            Haptics.soft()
                            toggleReason(reason)
                        } label: {
                            Chip(title: reason.rawValue, icon: reason.icon, selected: selected)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(GlassCard())
    }

    private var remindersCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.mint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Reminders")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.cream)
                Text("Optional prompts with discreet Lock Screen wording")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.mutedInk)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: remindersBinding)
                .labelsHidden()
                .tint(Theme.mint)
        }
        .padding(18)
        .background(GlassCard())
    }

    private var remindersBinding: Binding<Bool> {
        Binding(
            get: { model.data.remindersEnabled },
            set: { isOn in
                model.data.remindersEnabled = isOn
                if isOn {
                    Task {
                        let granted = await Reminders.requestAuthorization()
                        if !granted { model.data.remindersEnabled = false }
                        model.refreshReminders()
                    }
                } else {
                    model.refreshReminders()
                }
            })
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.mint)
            Text("Clearing is a personal support tool, not medical care. Your experience may differ from anyone else's. If quitting, sleep, or mood feels unmanageable, a clinician or support service can help.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(GlassCard())
    }

    private var resetButton: some View {
        Button {
            showResetConfirm = true
        } label: {
            Text("Reset progress")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Capsule().stroke(Theme.danger.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private var footer: some View {
        Text("Clearing 1.0 · made with care")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.cream.opacity(0.3))
            .padding(.top, 4)
    }

    private func settingRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.mutedInk)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.cream)
        }
        .padding(.vertical, 13)
    }

    private func settingLabel(_ title: String) -> some View {
        Text(title)
            .font(Theme.rounded(12, .bold))
            .textCase(.uppercase)
            .foregroundStyle(Theme.mutedInk)
    }

    private func toggleReason(_ reason: Reason) {
        if model.data.reasons.contains(reason.rawValue) {
            model.data.reasons.removeAll { $0 == reason.rawValue }
        } else {
            model.data.reasons.append(reason.rawValue)
        }
    }
}
