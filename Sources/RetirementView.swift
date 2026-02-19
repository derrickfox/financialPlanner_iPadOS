import Charts
import SwiftUI

struct RetirementView: View {
    @Binding var inputs: RetirementInputs
    let onSwitch: () -> Void

    @State private var expandedGroups = Set(retirementFieldGroups.map(\.id))

    private var analysis: RetirementAnalysis {
        RetirementCalculator.compute(inputs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HeaderView(
                title: "Retirement Calculator",
                description: "Model retirement readiness using savings, contributions, market returns, inflation, taxes, Social Security, pension income, and monthly budgeting.",
                toggleLabel: "Rent vs Buy Calculator",
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
                    inputs = RetirementInputs()
                }
                .buttonStyle(.bordered)
                .tint(Theme.muted)
            }

            ForEach(retirementFieldGroups) { group in
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
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)

                HStack(spacing: 10) {
                    MetricCard(
                        title: "Balance At Retirement",
                        value: Formatters.currency(summary.balanceAtRetirement)
                    )
                    MetricCard(
                        title: "Withdrawal-Rule Target",
                        value: Formatters.currency(summary.requiredNestEgg)
                    )
                    MetricCard(
                        title: "Sustainable Monthly Spend",
                        value: Formatters.currency(summary.sustainableMonthlySpend)
                    )
                }

                Text(sublineMessage(lifeExpectancy: assumptions.lifeExpectancy))
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
                    Text("Portfolio Balance By Age")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("Includes contributions, growth, withdrawals, inflation, and taxes.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.muted)

                    Chart {
                        ForEach(analysis.timeline) { point in
                            LineMark(
                                x: .value("Age", point.age),
                                y: .value("Balance", point.balance)
                            )
                            .foregroundStyle(Theme.retirement)
                            .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        }

                        RuleMark(x: .value("Retirement", assumptions.retirementAge))
                            .foregroundStyle(Color.gray.opacity(0.7))
                            .lineStyle(.init(lineWidth: 1.5, dash: [5, 4]))
                            .annotation(position: .top) {
                                Text("Retirement")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Theme.muted)
                            }
                    }
                    .frame(height: 280)
                }
            }

            PanelCard {
                monthlyBudgetPanel
            }

            PanelCard {
                retirementBreakdownPanel
            }
        }
    }

    private var monthlyBudgetPanel: some View {
        let summary = analysis.summary
        let deltaPositive = summary.monthlyBudgetDelta >= 0

        return VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Budget At Retirement")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
            Text("Planned monthly expenses are inflated to retirement age and compared against estimated sustainable monthly spending.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.muted)

            HStack(spacing: 10) {
                MetricCard(
                    title: "Planned Monthly Spend",
                    value: Formatters.currency(summary.plannedMonthlySpendAtRetirement)
                )
                MetricCard(
                    title: "Sustainable Monthly Spend",
                    value: Formatters.currency(summary.sustainableMonthlySpend)
                )
                MetricCard(
                    title: "Monthly Cushion / Gap",
                    value: (deltaPositive ? "+" : "-") + Formatters.currency(abs(summary.monthlyBudgetDelta)),
                    valueColor: deltaPositive ? Theme.positive : Theme.negative
                )
            }

            VStack(spacing: 6) {
                budgetHeaderRow

                ForEach(summary.monthlyBudgetRows) { row in
                    HStack(spacing: 12) {
                        Text(row.label)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.text)

                        Spacer(minLength: 8)

                        Text(Formatters.currency(row.today))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 110, alignment: .trailing)

                        Text(Formatters.currency(row.atRetirement))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.text)
                            .frame(width: 120, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.988, green: 0.98, blue: 0.957))
                    )
                }
            }
            .padding(.top, 4)
        }
    }

    private var budgetHeaderRow: some View {
        HStack(spacing: 12) {
            Text("Category")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.muted)
                .textCase(.uppercase)

            Spacer(minLength: 8)

            Text("Today")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.muted)
                .frame(width: 110, alignment: .trailing)

            Text("At Retirement")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.muted)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 8)
    }

    private var retirementBreakdownPanel: some View {
        let summary = analysis.summary
        let rows: [RetirementBreakdownRow] = [
            RetirementBreakdownRow(label: "Balance At Retirement", value: summary.balanceAtRetirement, color: Theme.retirement),
            RetirementBreakdownRow(label: "Target Nest Egg", value: summary.requiredNestEgg, color: Theme.target),
            RetirementBreakdownRow(label: "Planned Annual Spend", value: summary.plannedMonthlySpendAtRetirement * 12, color: Theme.target),
            RetirementBreakdownRow(label: "Sustainable Annual Spend", value: summary.sustainableAnnualSpend, color: Theme.retirement),
            RetirementBreakdownRow(label: "Projected End Balance", value: summary.finalBalance, color: Theme.buy),
            RetirementBreakdownRow(label: "Total Withdrawals", value: summary.cumulativeWithdrawals, color: Theme.rent)
        ]
        let maxValue = max(rows.map { abs($0.value) }.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Retirement Breakdown")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
            Text("Bars compare your target, savings progress, and retirement cashflow.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.muted)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(row.label)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.text)
                            Spacer(minLength: 8)
                            Text(Formatters.currency(row.value))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.muted)
                        }

                        GeometryReader { proxy in
                            let ratio = min(abs(row.value) / maxValue, 1)
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(red: 0.95, green: 0.93, blue: 0.89))

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [row.color, row.color.opacity(0.62)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: proxy.size.width * ratio)
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var outcomeMessage: String {
        let summary = analysis.summary
        if summary.retireReady {
            return "On track: projected balance beats your withdrawal-rule target by \(Formatters.currency(abs(summary.targetGap))) at retirement."
        }

        return "Gap to target: increase projected retirement assets by \(Formatters.currency(abs(summary.targetGap))) to meet your withdrawal-rule target."
    }

    private func sublineMessage(lifeExpectancy: Int) -> String {
        let summary = analysis.summary
        let budgetMessage: String
        if summary.monthlyBudgetDelta >= 0 {
            budgetMessage = "Estimated monthly cushion at retirement: \(Formatters.currency(summary.monthlyBudgetDelta))."
        } else {
            budgetMessage = "Estimated monthly shortfall at retirement: \(Formatters.currency(abs(summary.monthlyBudgetDelta)))."
        }

        if let runOutAge = summary.runOutAge {
            return "Portfolio depletes around age \(runOutAge). \(budgetMessage)"
        }

        return "Portfolio remains funded through age \(lifeExpectancy). \(budgetMessage)"
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

    private func binding(for key: RetirementFieldKey) -> Binding<Double> {
        switch key {
        case .currentAge: return $inputs.currentAge
        case .retirementAge: return $inputs.retirementAge
        case .lifeExpectancy: return $inputs.lifeExpectancy
        case .currentSavings: return $inputs.currentSavings
        case .annualContribution: return $inputs.annualContribution
        case .employerMatchAnnual: return $inputs.employerMatchAnnual
        case .contributionGrowthPct: return $inputs.contributionGrowthPct
        case .preRetirementReturnPct: return $inputs.preRetirementReturnPct
        case .postRetirementReturnPct: return $inputs.postRetirementReturnPct
        case .investmentDragPct: return $inputs.investmentDragPct
        case .monthlyHousing: return $inputs.monthlyHousing
        case .monthlyUtilities: return $inputs.monthlyUtilities
        case .monthlyFood: return $inputs.monthlyFood
        case .monthlyTransportation: return $inputs.monthlyTransportation
        case .monthlyHealthcare: return $inputs.monthlyHealthcare
        case .monthlyLifestyle: return $inputs.monthlyLifestyle
        case .monthlyTravel: return $inputs.monthlyTravel
        case .monthlyOther: return $inputs.monthlyOther
        case .annualNonMonthlyExpenses: return $inputs.annualNonMonthlyExpenses
        case .socialSecurityAnnual: return $inputs.socialSecurityAnnual
        case .pensionAnnual: return $inputs.pensionAnnual
        case .benefitIncreasePct: return $inputs.benefitIncreasePct
        case .inflationPct: return $inputs.inflationPct
        case .retirementIncomeTaxPct: return $inputs.retirementIncomeTaxPct
        case .safeWithdrawalRatePct: return $inputs.safeWithdrawalRatePct
        }
    }
}

private struct RetirementBreakdownRow: Identifiable {
    let label: String
    let value: Double
    let color: Color

    var id: String { label }
}
