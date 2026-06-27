import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(progress: 0.1)

                ScrollView {
                    VStack(spacing: 16) {
                        whyCard
                        statsCard
                        remindersCard
                        upgradeCard
                        disclaimerCard
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
                    Button("Done") { dismiss() }.foregroundStyle(Theme.mint)
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var whyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Why you're quitting", systemImage: "target")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.cream)
            if model.data.reasons.isEmpty {
                Text("No reasons set yet.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.cream.opacity(0.5))
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(model.data.reasons, id: \.self) { reason in
                        Chip(title: reason, selected: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(GlassCard())
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            settingRow("Clear since", value: model.cleanStart.formatted(date: .abbreviated, time: .omitted))
            Divider().overlay(.white.opacity(0.08))
            settingRow("Weekly cost", value: model.data.weeklySpend.asMoney)
            Divider().overlay(.white.opacity(0.08))
            settingRow("Urges beaten", value: "\(model.urgesBeaten)")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
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
                Text("Daily check-in + milestone alerts")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.cream.opacity(0.55))
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

    @ViewBuilder private var upgradeCard: some View {
        if store.isPremium {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clearing Plus is active")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.cream)
                    Text("Thanks for going all in.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.cream.opacity(0.6))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(goldCardBackground)
        } else {
            Button {
                Haptics.soft()
                showPaywall = true
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Clearing Plus", systemImage: "sparkles")
                            .font(Theme.rounded(16, .bold))
                            .foregroundStyle(Theme.gold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.gold.opacity(0.7))
                    }
                    Text("Lock Screen & StandBy widgets, custom milestone reminders, and the full recovery library.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.cream.opacity(0.6))
                        .multilineTextAlignment(.leading)
                    Text("Try free, then \(29.99.asMoney)/yr")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.cream)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(goldCardBackground)
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var goldCardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Theme.gold.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.gold.opacity(0.25), lineWidth: 1))
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.mint)
            Text("Clearing is a personal tracker and support tool — not medical advice. Recovery facts are general information. If you're struggling, please reach out to a doctor or a support line.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.cream.opacity(0.55))
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
                .foregroundStyle(Theme.cream.opacity(0.7))
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.cream)
        }
        .padding(.vertical, 13)
    }
}
