import Charts
import SwiftUI

struct RentVsBuyView: View {
    @Binding var inputs: RentVsBuyInputs
    let onSwitch: () -> Void

    @State private var expandedGroups = Set(rentVsBuyFieldGroups.map(\.id))

    private var analysis: RentVsBuyAnalysis {
        RentVsBuyCalculator.compute(inputs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HeaderView(
                title: "Rent vs Buy Calculator",
                description: "Adjust assumptions and compare long-term housing costs, taxes, maintenance, equity, and investment opportunity cost in real time.",
                toggleLabel: "Retirement Calculator",
                onToggle: onSwitch
            )

            AdaptivePanels {
                PanelCard {
                    controlsPanel
                }
            } right: {
                PanelCard {
                    resultsPanel
                }
            }
        }
    }

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Inputs")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)

                Spacer()

                Button("Reset") {
                    inputs = RentVsBuyInputs()
                }
                .buttonStyle(.bordered)
                .tint(Theme.muted)
            }

            ForEach(rentVsBuyFieldGroups) { group in
                CollapsibleGroup(
                    title: group.title,
                    isExpanded: isExpandedBinding(for: group.id)
                ) {
                    ForEach(group.fields) { field in
                        NumericInputRow(
                            label: field.label,
                            suffix: field.suffix,
                            range: field.range,
                            step: field.step,
                            value: binding(for: field.key)
                        )
                    }
                }
            }
        }
    }

    private var resultsPanel: some View {
        let summary = analysis.summary
        let assumptions = analysis.assumptions

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(outcomeMessage)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)

                HStack(spacing: 10) {
                    MetricCard(
                        title: "Renting Net Cost",
                        value: Formatters.currency(summary.renterNetCost)
                    )
                    MetricCard(
                        title: "Buying Net Cost",
                        value: Formatters.currency(summary.ownerNetCost)
                    )
                    MetricCard(
                        title: "Estimated Mortgage Payment",
                        value: "\(Formatters.currency(assumptions.monthlyMortgagePayment))/mo"
                    )
                }

                Text(breakEvenMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.muted)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .stroke(Color(red: 0.9, green: 0.88, blue: 0.82), lineWidth: 1)
            )

            PanelCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Net Cost Over Time")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("Net cost = total cash outflows minus current assets.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.muted)

                    Chart(netCostSeriesPoints) { point in
                        LineMark(
                            x: .value("Year", point.year),
                            y: .value("Net Cost", point.netCost)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(by: .value("Scenario", point.scenario))
                        .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    .frame(height: 280)
                    .chartLegend(position: .bottom, spacing: 20)
                    .chartForegroundStyleScale([
                        "Renting": Theme.rent,
                        "Buying": Theme.buy
                    ])
                }
            }

            PanelCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scenario Breakdown")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("Absolute bar length reflects amount in each category.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.muted)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(breakdownRows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(row.label)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.text)

                                HStack(spacing: 8) {
                                    Text("Rent \(Formatters.currency(row.rentValue))")
                                    Spacer(minLength: 8)
                                    Text("Buy \(Formatters.currency(row.buyValue))")
                                }
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.muted)

                                amountTrack(value: row.rentValue, color: Theme.rent)
                                amountTrack(value: row.buyValue, color: Theme.buy)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
    }

    private var outcomeMessage: String {
        let summary = analysis.summary
        let years = analysis.assumptions.years

        if summary.winner == "buy" {
            return "Buying is lower by \(Formatters.currency(summary.costDifference)) over \(years) years."
        }
        if summary.winner == "rent" {
            return "Renting is lower by \(Formatters.currency(abs(summary.costDifference))) over \(years) years."
        }
        return "Both scenarios end with the same estimated net cost."
    }

    private var breakEvenMessage: String {
        let assumptions = analysis.assumptions
        if let breakEvenYear = analysis.summary.breakEvenYear {
            return "Estimated break-even: year \(String(format: "%.1f", breakEvenYear))."
        }
        return "No break-even point within \(assumptions.years) years."
    }

    private var breakdownRows: [BreakdownRow] {
        let summary = analysis.summary
        let years = analysis.assumptions.years
        return [
            BreakdownRow(label: "Net cost after \(years) years", rentValue: summary.renterNetCost, buyValue: summary.ownerNetCost),
            BreakdownRow(label: "Total cash paid", rentValue: summary.renterOutflow, buyValue: summary.ownerOutflow),
            BreakdownRow(label: "Asset value at end", rentValue: summary.renterInvestment, buyValue: summary.ownerEquity)
        ]
    }

    private var breakdownMaxValue: Double {
        max(
            breakdownRows
                .flatMap { [abs($0.rentValue), abs($0.buyValue)] }
                .max() ?? 1,
            1
        )
    }

    private var netCostSeriesPoints: [NetCostSeriesPoint] {
        analysis.timeline.flatMap { point in
            [
                NetCostSeriesPoint(year: point.year, netCost: point.renterNetCost, scenario: "Renting"),
                NetCostSeriesPoint(year: point.year, netCost: point.ownerNetCost, scenario: "Buying")
            ]
        }
    }

    private func amountTrack(value: Double, color: Color) -> some View {
        GeometryReader { proxy in
            let ratio = min(abs(value) / breakdownMaxValue, 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.95, green: 0.93, blue: 0.89))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.62)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * ratio)
            }
        }
        .frame(height: 10)
    }

    private func isExpandedBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { expandedGroups.contains(id) },
            set: { isOpen in
                if isOpen {
                    expandedGroups.insert(id)
                } else {
                    expandedGroups.remove(id)
                }
            }
        )
    }

    private func binding(for key: RentVsBuyFieldKey) -> Binding<Double> {
        switch key {
        case .years: return $inputs.years
        case .monthlyRent: return $inputs.monthlyRent
        case .rentIncreasePct: return $inputs.rentIncreasePct
        case .rentersInsuranceMonthly: return $inputs.rentersInsuranceMonthly
        case .homePrice: return $inputs.homePrice
        case .downPaymentPct: return $inputs.downPaymentPct
        case .mortgageRatePct: return $inputs.mortgageRatePct
        case .loanTermYears: return $inputs.loanTermYears
        case .propertyTaxPct: return $inputs.propertyTaxPct
        case .homeInsuranceAnnual: return $inputs.homeInsuranceAnnual
        case .maintenancePct: return $inputs.maintenancePct
        case .hoaMonthly: return $inputs.hoaMonthly
        case .closingCostPct: return $inputs.closingCostPct
        case .sellingCostPct: return $inputs.sellingCostPct
        case .homeAppreciationPct: return $inputs.homeAppreciationPct
        case .investmentReturnPct: return $inputs.investmentReturnPct
        case .annualInflationPct: return $inputs.annualInflationPct
        }
    }
}

private struct BreakdownRow: Identifiable {
    let label: String
    let rentValue: Double
    let buyValue: Double

    var id: String { label }
}

private struct NetCostSeriesPoint: Identifiable {
    let year: Int
    let netCost: Double
    let scenario: String

    var id: String { "\(scenario)-\(year)" }
}
