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

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.text.opacity(0.95))

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                TextField("", value: $value, formatter: Formatters.numberInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 122)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)

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

            if let detailText {
                Text(detailText)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
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
