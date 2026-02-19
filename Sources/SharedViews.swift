import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.pageGradient

            Circle()
                .fill(Color.orange.opacity(0.14))
                .frame(width: 360, height: 360)
                .offset(x: -280, y: -350)

            Circle()
                .fill(Color.teal.opacity(0.16))
                .frame(width: 320, height: 320)
                .offset(x: 300, y: -380)

            Circle()
                .fill(Color.orange.opacity(0.12))
                .frame(width: 320, height: 320)
                .offset(x: 260, y: 460)
        }
        .ignoresSafeArea()
    }
}

struct PanelCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.panelStroke, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 16)
            )
    }
}

struct HeaderView: View {
    let title: String
    let description: String
    let toggleLabel: String
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Interactive Financial Model")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)

                Text(title)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)

                Text(description)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.text.opacity(0.9))
                    .lineLimit(nil)
            }

            Spacer(minLength: 10)

            Button(action: onToggle) {
                Text(toggleLabel)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.84, green: 0.82, blue: 0.77), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

struct NumericInputRow: View {
    let label: String
    let suffix: String
    let range: ClosedRange<Double>?
    let step: Double
    @Binding var value: Double
    @State private var isPadPresented = false
    @State private var draftText = ""

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.text.opacity(0.95))

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button {
                    draftText = formattedNumber(value)
                    isPadPresented = true
                } label: {
                    Text(formattedNumber(value))
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.text)
                        .frame(width: 122, alignment: .trailing)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.84, green: 0.82, blue: 0.77), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .popover(
                    isPresented: $isPadPresented,
                    attachmentAnchor: .point(.trailing),
                    arrowEdge: .leading
                ) {
                    NumericPadPopover(
                        title: label,
                        suffix: suffix,
                        step: step,
                        range: range,
                        draftText: $draftText,
                        onCancel: { isPadPresented = false },
                        onApply: { nextValue in
                            value = nextValue
                            isPadPresented = false
                        }
                    )
                    .presentationCompactAdaptation(.none)
                }

                Text(suffix)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 70, alignment: .leading)
            }
        }
        .onChange(of: value) { _, newValue in
            var sanitized = newValue
            if !sanitized.isFinite {
                sanitized = 0
            }
            if let range {
                sanitized = Swift.max(Swift.min(sanitized, range.upperBound), range.lowerBound)
            }
            if sanitized != value {
                value = sanitized
            }
        }
    }

    private func formattedNumber(_ number: Double) -> String {
        Formatters.numberInput.string(from: NSNumber(value: number)) ?? "0"
    }
}

private struct NumericPadPopover: View {
    let title: String
    let suffix: String
    let step: Double
    let range: ClosedRange<Double>?
    @Binding var draftText: String
    let onCancel: () -> Void
    let onApply: (Double) -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text)

            HStack(spacing: 8) {
                Text(displayValue)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                Text(suffix)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.988, green: 0.98, blue: 0.957))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.87, green: 0.84, blue: 0.78), lineWidth: 1)
                    )
            )

            HStack(spacing: 8) {
                NumericPadButton(label: "-\(stepText)") {
                    applyDelta(-step)
                }
                NumericPadButton(label: "+\(stepText)") {
                    applyDelta(step)
                }
                NumericPadButton(label: "+/-") {
                    toggleSign()
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(["7", "8", "9", "4", "5", "6", "1", "2", "3", ".", "0", "Del"], id: \.self) { key in
                    NumericPadButton(label: key) {
                        handleKey(key)
                    }
                }
            }

            HStack(spacing: 8) {
                NumericPadButton(label: "Cancel") {
                    onCancel()
                }
                NumericPadButton(label: "Clear", accent: true) {
                    draftText = ""
                }
                NumericPadButton(label: "Done", accent: true) {
                    applyDraftValue()
                }
            }
        }
        .padding(12)
        .frame(width: 258)
    }

    private var displayValue: String {
        draftText.isEmpty ? "0" : draftText
    }

    private var stepText: String {
        Formatters.numberInput.string(from: NSNumber(value: step)) ?? "1"
    }

    private func applyDelta(_ delta: Double) {
        let base = Double(draftText) ?? 0
        setDraft(base + delta)
    }

    private func toggleSign() {
        if draftText.hasPrefix("-") {
            draftText.removeFirst()
        } else if !(range?.lowerBound ?? -Double.infinity >= 0) {
            draftText = draftText.isEmpty ? "-" : "-" + draftText
        }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "Del":
            if !draftText.isEmpty {
                draftText.removeLast()
            }
        case ".":
            if draftText.isEmpty {
                draftText = "0."
            } else if !draftText.contains(".") && draftText != "-" {
                draftText.append(".")
            }
        default:
            guard key.allSatisfy(\.isNumber) else { return }
            if draftText == "0" {
                draftText = key
            } else if draftText == "-0" {
                draftText = "-" + key
            } else {
                draftText.append(key)
            }
        }
    }

    private func applyDraftValue() {
        var nextValue = Double(draftText) ?? 0
        if !nextValue.isFinite {
            nextValue = 0
        }
        if let range {
            nextValue = max(min(nextValue, range.upperBound), range.lowerBound)
        }
        onApply(nextValue)
    }

    private func setDraft(_ rawValue: Double) {
        var nextValue = rawValue
        if let range {
            nextValue = max(min(nextValue, range.upperBound), range.lowerBound)
        }
        draftText = Formatters.numberInput.string(from: NSNumber(value: nextValue)) ?? "0"
    }
}

private struct NumericPadButton: View {
    let label: String
    let accent: Bool
    let action: () -> Void

    init(label: String, accent: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.accent = accent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(accent ? Color.white : Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent ? Theme.buy : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    accent
                                        ? Theme.buy
                                        : Color(red: 0.87, green: 0.84, blue: 0.78),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct CollapsibleGroup<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content

    init(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack {
                    Text(title.uppercased())
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Theme.muted)

                    Spacer()

                    Text(isExpanded ? "Hide" : "Show")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 0.87, green: 0.84, blue: 0.78), lineWidth: 1)
                                )
                        )
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    content
                }
            }
        }
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Divider().background(Color(red: 0.84, green: 0.82, blue: 0.77))
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let valueColor: Color?
    let detailText: String?

    init(title: String, value: String, valueColor: Color? = nil, detailText: String? = nil) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.detailText = detailText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(Theme.muted)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor ?? Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Group {
                if let detailText {
                    Text(detailText)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(3)
                } else {
                    Color.clear
                }
            }
            .frame(height: 38, alignment: .topLeading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.91, green: 0.89, blue: 0.84), lineWidth: 1)
                )
        )
    }
}

struct AdaptivePanels<Left: View, Right: View>: View {
    let left: Left
    let right: Right
    @State private var availableWidth: CGFloat = 0

    init(
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self.left = left()
        self.right = right()
    }

    var body: some View {
        Group {
            if availableWidth >= 940 {
                HStack(alignment: .top, spacing: 14) {
                    left
                        .frame(width: 360)
                    right
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                VStack(spacing: 14) {
                    left
                    right
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        availableWidth = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        availableWidth = newWidth
                    }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: availableWidth >= 940)
    }
}
