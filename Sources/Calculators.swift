import Foundation

// AI_CHANGE:
// Tool: Claude Code
// Model: Claude Opus 4.8
// Timestamp: 2026-07-22T00:00:00-04:00
// Purpose: Ports the correctness fixes made to the RentVsBuy web app (REPOS/RentVsBuy,
//          commits f689148 and 3efa1e3) into this native port, which duplicated the same
//          model line for line and therefore reproduced all of its defects.
// Reason: This app shipped the same accounting asymmetry, unbounded portfolio drawdown,
//         appreciation off-by-one, retirement debt spiral and missing PMI. See the web repo's
//         src/lib/*.test.js for the suite that pins each of these.
struct OwnerMonthlyCostBreakdown {
    let principalInterestMonthly: Double
    let propertyTaxMonthly: Double
    let homeInsuranceMonthly: Double
    let hoaMonthly: Double
    let maintenanceMonthly: Double
    let pmiMonthly: Double

    var total: Double {
        principalInterestMonthly
            + propertyTaxMonthly
            + homeInsuranceMonthly
            + hoaMonthly
            + maintenanceMonthly
            + pmiMonthly
    }
}

/// Private mortgage insurance is charged until the loan amortizes below this share of the
/// original purchase price — keyed to the purchase price, not the appreciated value, which is
/// how lenders actually drop it.
let pmiCancellationLTV = 0.8

func monthlyPmi(loanBalance: Double, homePrice: Double, pmiRatePct: Double, originalLoanAmount: Double) -> Double {
    guard homePrice > 0, loanBalance > 0 else { return 0 }
    guard loanBalance > homePrice * pmiCancellationLTV else { return 0 }

    return (originalLoanAmount * max(pmiRatePct, 0) / 100) / 12
}

enum RentVsBuyCalculator {
    static func computeOwnerMonthlyCost(_ inputs: RentVsBuyInputs) -> OwnerMonthlyCostBreakdown {
        let homePrice = max(inputs.homePrice, 0)
        let downPaymentRate = clamp(inputs.downPaymentPct, min: 0, max: 100) / 100
        let mortgageRatePct = max(inputs.mortgageRatePct, 0)
        let loanTermYears = Int(clamp(round(inputs.loanTermYears), min: 1, max: 40))
        let propertyTaxRate = max(inputs.propertyTaxPct, 0) / 100
        let homeInsuranceAnnual = max(inputs.homeInsuranceAnnual, 0)
        let hoaMonthly = max(inputs.hoaMonthly, 0)
        let maintenanceRate = max(inputs.maintenancePct, 0) / 100
        let pmiRatePct = max(inputs.pmiRatePct, 0)

        let mortgagePrincipal = homePrice * (1 - downPaymentRate)
        let principalInterestMonthly = mortgagePayment(
            principal: mortgagePrincipal,
            annualRatePct: mortgageRatePct,
            termYears: loanTermYears
        )
        let propertyTaxMonthly = (homePrice * propertyTaxRate) / 12
        let homeInsuranceMonthly = homeInsuranceAnnual / 12
        let maintenanceMonthly = (homePrice * maintenanceRate) / 12

        return OwnerMonthlyCostBreakdown(
            principalInterestMonthly: principalInterestMonthly,
            propertyTaxMonthly: propertyTaxMonthly,
            homeInsuranceMonthly: homeInsuranceMonthly,
            hoaMonthly: hoaMonthly,
            maintenanceMonthly: maintenanceMonthly,
            pmiMonthly: monthlyPmi(
                loanBalance: mortgagePrincipal,
                homePrice: homePrice,
                pmiRatePct: pmiRatePct,
                originalLoanAmount: mortgagePrincipal
            )
        )
    }

    static func compute(_ inputs: RentVsBuyInputs) -> RentVsBuyAnalysis {
        let years = Int(clamp(round(inputs.years), min: 1, max: 50))
        let monthlyRentStart = max(inputs.monthlyRent, 0)
        let rentIncreasePct = inputs.rentIncreasePct
        let rentersInsuranceStart = max(inputs.rentersInsuranceMonthly, 0)
        let homePrice = max(inputs.homePrice, 0)
        let downPaymentRate = clamp(inputs.downPaymentPct, min: 0, max: 100) / 100
        let mortgageRatePct = max(inputs.mortgageRatePct, 0)
        let loanTermYears = Int(clamp(round(inputs.loanTermYears), min: 1, max: 40))
        let propertyTaxRate = max(inputs.propertyTaxPct, 0) / 100
        let homeInsuranceAnnualStart = max(inputs.homeInsuranceAnnual, 0)
        let maintenanceRate = max(inputs.maintenancePct, 0) / 100
        let pmiRatePct = max(inputs.pmiRatePct, 0)
        let hoaStart = max(inputs.hoaMonthly, 0)
        let closingCostRate = max(inputs.closingCostPct, 0) / 100
        let sellingCostRate = clamp(inputs.sellingCostPct, min: 0, max: 100) / 100
        let appreciationPct = inputs.homeAppreciationPct
        let investmentReturnPct = inputs.investmentReturnPct
        let inflationPct = inputs.annualInflationPct

        let ownerMonthlyCostBreakdown = computeOwnerMonthlyCost(inputs)

        let downPayment = homePrice * downPaymentRate
        let closingCosts = homePrice * closingCostRate
        let mortgagePrincipal = homePrice - downPayment
        let monthlyMortgagePayment = ownerMonthlyCostBreakdown.principalInterestMonthly
        let mortgageMonths = loanTermYears * 12
        let monthlyMortgageRate = mortgageRatePct / 100 / 12

        let monthlyRentGrowth = annualToMonthlyRate(rentIncreasePct)
        let monthlyHomeGrowth = annualToMonthlyRate(appreciationPct)
        let monthlyInvestmentGrowth = annualToMonthlyRate(investmentReturnPct)
        let monthlyInflation = annualToMonthlyRate(inflationPct)

        var rent = monthlyRentStart
        var rentersInsurance = rentersInsuranceStart
        var homeInsurance = homeInsuranceAnnualStart / 12
        var hoa = hoaStart
        var homeValue = homePrice
        var remainingBalance = mortgagePrincipal

        var ownerOutflow = downPayment + closingCosts
        // The renter diverts the same up-front cash into the market rather than into a house,
        // so it counts as outflow for them too.
        var renterOutflow = downPayment + closingCosts
        var renterRentPaid = 0.0
        var renterInvestment = downPayment + closingCosts

        var timeline: [RentVsBuyPoint] = []
        var breakEvenYear: Double?

        for month in 1...(years * 12) {
            if month > 1 {
                rent *= (1 + monthlyRentGrowth)
                rentersInsurance *= (1 + monthlyInflation)
                homeInsurance *= (1 + monthlyInflation)
                hoa *= (1 + monthlyInflation)
            }

            // The home starts appreciating immediately, unlike the recurring costs which
            // begin at today's amount. Sharing the guard left every year-N snapshot one month
            // short of N years of growth.
            homeValue *= (1 + monthlyHomeGrowth)

            renterInvestment *= (1 + monthlyInvestmentGrowth)

            // Captured before this month's principal payment: the PMI premium falls due
            // alongside the payment, so it is assessed on the opening balance.
            let openingBalance = remainingBalance

            var mortgagePaymentThisMonth = 0.0
            if month <= mortgageMonths, remainingBalance > 0.01 {
                let interestPaid = remainingBalance * monthlyMortgageRate
                var principalPaid = max(monthlyMortgagePayment - interestPaid, 0)

                if principalPaid > remainingBalance {
                    principalPaid = remainingBalance
                }

                mortgagePaymentThisMonth = interestPaid + principalPaid
                remainingBalance -= principalPaid
            }

            let propertyTaxThisMonth = (homeValue * propertyTaxRate) / 12
            let maintenanceThisMonth = (homeValue * maintenanceRate) / 12

            let pmiThisMonth = monthlyPmi(
                loanBalance: openingBalance,
                homePrice: homePrice,
                pmiRatePct: pmiRatePct,
                originalLoanAmount: mortgagePrincipal
            )

            let ownerMonthlyCost = mortgagePaymentThisMonth
                + propertyTaxThisMonth
                + maintenanceThisMonth
                + homeInsurance
                + hoa
                + pmiThisMonth
            let renterMonthlyCost = rent + rentersInsurance

            ownerOutflow += ownerMonthlyCost
            renterRentPaid += renterMonthlyCost

            // Portfolio contributions are cash the renter commits, so they belong in the
            // outflow both scenarios are compared on. Draws are capped at the balance, so an
            // exhausted portfolio forces out-of-pocket spending rather than margin debt.
            let renterContribution = ownerMonthlyCost - renterMonthlyCost

            if renterContribution >= 0 {
                renterInvestment += renterContribution
                renterOutflow += renterMonthlyCost + renterContribution
            } else {
                let shortfall = -renterContribution
                let fundedFromPortfolio = Swift.min(renterInvestment, shortfall)
                renterInvestment -= fundedFromPortfolio
                renterOutflow += renterMonthlyCost - fundedFromPortfolio
            }

            let ownerEquity = homeValue * (1 - sellingCostRate) - remainingBalance
            let ownerNetCost = ownerOutflow - ownerEquity
            let renterNetCost = renterOutflow - renterInvestment

            if breakEvenYear == nil, ownerNetCost <= renterNetCost {
                breakEvenYear = Double(month) / 12
            }

            if month.isMultiple(of: 12) {
                timeline.append(
                    RentVsBuyPoint(
                        year: month / 12,
                        ownerNetCost: ownerNetCost,
                        renterNetCost: renterNetCost,
                        ownerOutflow: ownerOutflow,
                        renterOutflow: renterOutflow,
                        renterRentPaid: renterRentPaid,
                        ownerEquity: ownerEquity,
                        renterInvestment: renterInvestment
                    )
                )
            }
        }

        let finalYear = timeline.last ?? RentVsBuyPoint(
            year: years,
            ownerNetCost: 0,
            renterNetCost: 0,
            ownerOutflow: 0,
            renterOutflow: 0,
            renterRentPaid: 0,
            ownerEquity: 0,
            renterInvestment: 0
        )

        let costDifference = finalYear.renterNetCost - finalYear.ownerNetCost
        let winner: String
        if costDifference > 0 {
            winner = "buy"
        } else if costDifference < 0 {
            winner = "rent"
        } else {
            winner = "tie"
        }

        return RentVsBuyAnalysis(
            assumptions: RentVsBuyAssumptions(
                years: years,
                monthlyMortgagePayment: monthlyMortgagePayment
            ),
            timeline: timeline,
            summary: RentVsBuySummary(
                winner: winner,
                breakEvenYear: breakEvenYear,
                costDifference: costDifference,
                ownerNetCost: finalYear.ownerNetCost,
                renterNetCost: finalYear.renterNetCost,
                ownerOutflow: finalYear.ownerOutflow,
                renterOutflow: finalYear.renterOutflow,
                renterRentPaid: finalYear.renterRentPaid,
                ownerEquity: finalYear.ownerEquity,
                renterInvestment: finalYear.renterInvestment
            )
        )
    }
}

enum RetirementCalculator {
    private struct MonthlyExpenseRow {
        let label: String
        let today: Double
    }

    private struct Projection {
        let timeline: [RetirementPoint]
        let runOutAge: Int?
        let balanceAtRetirement: Double
        let cumulativeContributions: Double
        let cumulativeWithdrawals: Double
        let finalBalance: Double
    }

    /// Runs one full projection from today through life expectancy. `spendingMultiplier` scales
    /// the planned retirement budget, which is what lets the sustainability solver ask "what if
    /// this household spent 80% of its plan?" without duplicating the projection logic.
    private static func project(_ inputs: RetirementInputs, spendingMultiplier: Double) -> Projection {
        let currentAge = Int(clamp(round(inputs.currentAge), min: 18, max: 90))
        let retirementAgeInput = Int(clamp(round(inputs.retirementAge), min: 40, max: 95))
        let retirementAge = max(retirementAgeInput, currentAge + 1)

        let lifeExpectancyInput = Int(clamp(round(inputs.lifeExpectancy), min: 55, max: 110))
        let lifeExpectancy = max(lifeExpectancyInput, retirementAge + 1)

        let currentSavings = max(inputs.currentSavings, 0)
        let annualContributionStart = max(inputs.annualContribution, 0)
        let employerMatchStart = max(inputs.employerMatchAnnual, 0)
        let contributionGrowthPct = inputs.contributionGrowthPct
        let preRetirementReturnPct = inputs.preRetirementReturnPct
        let postRetirementReturnPct = inputs.postRetirementReturnPct
        let investmentDragPct = max(inputs.investmentDragPct, 0)
        let inflationPct = inputs.inflationPct

        let monthlyHousing = max(inputs.monthlyHousing, 0)
        let monthlyUtilities = max(inputs.monthlyUtilities, 0)
        let monthlyFood = max(inputs.monthlyFood, 0)
        let monthlyTransportation = max(inputs.monthlyTransportation, 0)
        let monthlyHealthcare = max(inputs.monthlyHealthcare, 0)
        let monthlyLifestyle = max(inputs.monthlyLifestyle, 0)
        let monthlyTravel = max(inputs.monthlyTravel, 0)
        let monthlyOther = max(inputs.monthlyOther, 0)
        let annualNonMonthlyExpenses = max(inputs.annualNonMonthlyExpenses, 0)

        let socialSecurityStart = max(inputs.socialSecurityAnnual, 0)
        let pensionStart = max(inputs.pensionAnnual, 0)
        let benefitIncreasePct = inputs.benefitIncreasePct
        let retirementIncomeTaxRate = clamp(inputs.retirementIncomeTaxPct, min: 0, max: 95) / 100

        let yearsToRetirement = retirementAge - currentAge
        let yearsTotal = lifeExpectancy - currentAge

        let contributionGrowth = annualRateMultiplier(contributionGrowthPct)
        let inflationGrowth = annualRateMultiplier(inflationPct)
        let benefitsGrowth = annualRateMultiplier(benefitIncreasePct)
        let inflationToRetirement = pow(inflationGrowth, Double(yearsToRetirement))

        let expenseRows: [MonthlyExpenseRow] = [
            MonthlyExpenseRow(label: "Housing", today: monthlyHousing),
            MonthlyExpenseRow(label: "Utilities", today: monthlyUtilities),
            MonthlyExpenseRow(label: "Food & Groceries", today: monthlyFood),
            MonthlyExpenseRow(label: "Transportation", today: monthlyTransportation),
            MonthlyExpenseRow(label: "Healthcare", today: monthlyHealthcare),
            MonthlyExpenseRow(label: "Lifestyle", today: monthlyLifestyle),
            MonthlyExpenseRow(label: "Travel", today: monthlyTravel),
            MonthlyExpenseRow(label: "Other", today: monthlyOther),
            MonthlyExpenseRow(label: "Non-Monthly Costs (Avg)", today: annualNonMonthlyExpenses / 12)
        ]

        let plannedMonthlySpendToday = expenseRows.reduce(0) { partial, row in
            partial + row.today
        }
        let annualSpendingToday = plannedMonthlySpendToday * 12

        var balance = currentSavings
        var annualContribution = annualContributionStart
        var annualMatch = employerMatchStart
        var socialSecurity = socialSecurityStart
        var pension = pensionStart

        // AI_CHANGE:
        // Tool: Claude Code
        // Model: Claude Opus 4.8
        // Timestamp: 2026-07-22T00:00:00-04:00
        // Purpose: Runs the projection at a scalable spending level so sustainable spending can
        //          be solved against the simulation instead of a static withdrawal formula, and
        //          caps withdrawals at the remaining balance.
        // Reason: Ported from REPOS/RentVsBuy. Previously the balance went negative and kept
        //         compounding at the post-retirement return (reaching -$9.3M from a $10k start),
        //         and "sustainable spend" was a first-year safe-withdrawal estimate that ignored
        //         the user's own inflation, COLA and return assumptions.
        let firstYearRetirementSpending = annualSpendingToday * inflationToRetirement * spendingMultiplier
        var retirementSpending = firstYearRetirementSpending

        var cumulativeContributions = 0.0
        var cumulativeWithdrawals = 0.0
        var runOutAge: Int?

        // The withdrawal-rule target is derived once in compute(), not here — this function
        // runs many times during the sustainability solve and only reports the projection.
        var timeline: [RetirementPoint] = []
        var balanceAtRetirement = currentSavings

        for yearOffset in 0...yearsTotal {
            let age = currentAge + yearOffset
            let isRetired = age >= retirementAge
            let grossReturnRate = isRetired ? postRetirementReturnPct : preRetirementReturnPct
            let netReturnRate = grossReturnRate - investmentDragPct

            balance *= annualRateMultiplier(netReturnRate)

            var contributionThisYear = 0.0
            var withdrawalThisYear = 0.0
            var incomeThisYear = 0.0
            var spendingThisYear = 0.0

            if !isRetired {
                contributionThisYear = annualContribution + annualMatch
                balance += contributionThisYear
                cumulativeContributions += contributionThisYear

                if age + 1 == retirementAge {
                    balanceAtRetirement = balance
                }

                annualContribution *= contributionGrowth
                annualMatch *= contributionGrowth
            } else {
                spendingThisYear = retirementSpending
                incomeThisYear = socialSecurity + pension

                let shortfall = spendingThisYear - incomeThisYear
                var unfundedThisYear = 0.0
                if shortfall > 0 {
                    let needed = shortfall / max(1 - retirementIncomeTaxRate, 0.01)
                    let grossWithdrawal = Swift.min(needed, Swift.max(balance, 0))
                    withdrawalThisYear = grossWithdrawal
                    unfundedThisYear = needed - grossWithdrawal
                    balance -= grossWithdrawal
                    cumulativeWithdrawals += grossWithdrawal
                } else if shortfall < 0 {
                    contributionThisYear = abs(shortfall)
                    balance += contributionThisYear
                    cumulativeContributions += contributionThisYear
                }

                retirementSpending *= inflationGrowth
                socialSecurity *= benefitsGrowth
                pension *= benefitsGrowth

                // A plan that lands on exactly zero has funded every dollar of its spending, so
                // failure is keyed to unmet need rather than the balance touching zero.
                if runOutAge == nil, unfundedThisYear > 0 {
                    runOutAge = age
                }
            }

            timeline.append(
                RetirementPoint(
                    age: age,
                    isRetired: isRetired,
                    balance: balance,
                    contribution: contributionThisYear,
                    withdrawal: withdrawalThisYear,
                    retirementIncome: incomeThisYear,
                    retirementSpending: spendingThisYear
                )
            )
        }

        return Projection(
            timeline: timeline,
            runOutAge: runOutAge,
            balanceAtRetirement: balanceAtRetirement,
            cumulativeContributions: cumulativeContributions,
            cumulativeWithdrawals: cumulativeWithdrawals,
            finalBalance: timeline.last?.balance ?? 0
        )
    }

    // AI_CHANGE:
    // Tool: Claude Code
    // Model: Claude Opus 4.8
    // Timestamp: 2026-07-22T00:00:00-04:00
    // Purpose: Finds, by bisection, the largest fraction of the planned budget the portfolio can
    //          fund every year through life expectancy.
    // Reason: Ported from REPOS/RentVsBuy. "Sustainable spend" was balanceAtRetirement times the
    //         safe withdrawal rate — a first-year estimate that ignored the user's inflation,
    //         COLA and return inputs, so the reported cushion held for one year and no longer.
    private static let sustainableSpendCeiling = 20.0
    private static let sustainableSpendIterations = 48

    private static func solveSustainableSpendingMultiplier(_ inputs: RetirementInputs) -> Double {
        let plannedMonthly = max(inputs.monthlyHousing, 0)
            + max(inputs.monthlyUtilities, 0)
            + max(inputs.monthlyFood, 0)
            + max(inputs.monthlyTransportation, 0)
            + max(inputs.monthlyHealthcare, 0)
            + max(inputs.monthlyLifestyle, 0)
            + max(inputs.monthlyTravel, 0)
            + max(inputs.monthlyOther, 0)
            + max(inputs.annualNonMonthlyExpenses, 0) / 12

        guard plannedMonthly > 0 else { return 0 }

        if project(inputs, spendingMultiplier: sustainableSpendCeiling).runOutAge == nil {
            return sustainableSpendCeiling
        }

        var affordable = 0.0
        var unaffordable = sustainableSpendCeiling

        for _ in 0..<sustainableSpendIterations {
            let midpoint = (affordable + unaffordable) / 2
            if project(inputs, spendingMultiplier: midpoint).runOutAge == nil {
                affordable = midpoint
            } else {
                unaffordable = midpoint
            }
        }

        return affordable
    }

    static func compute(_ inputs: RetirementInputs) -> RetirementAnalysis {
        let currentAge = Int(clamp(round(inputs.currentAge), min: 18, max: 90))
        let retirementAgeInput = Int(clamp(round(inputs.retirementAge), min: 40, max: 95))
        let retirementAge = max(retirementAgeInput, currentAge + 1)
        let lifeExpectancyInput = Int(clamp(round(inputs.lifeExpectancy), min: 55, max: 110))
        let lifeExpectancy = max(lifeExpectancyInput, retirementAge + 1)

        let socialSecurityStart = max(inputs.socialSecurityAnnual, 0)
        let pensionStart = max(inputs.pensionAnnual, 0)
        let retirementIncomeTaxRate = clamp(inputs.retirementIncomeTaxPct, min: 0, max: 95) / 100
        let safeWithdrawalRate = clamp(inputs.safeWithdrawalRatePct, min: 0.5, max: 15) / 100

        let yearsToRetirement = retirementAge - currentAge
        let inflationToRetirement = pow(annualRateMultiplier(inputs.inflationPct), Double(yearsToRetirement))

        let expenseRows: [MonthlyExpenseRow] = [
            MonthlyExpenseRow(label: "Housing", today: max(inputs.monthlyHousing, 0)),
            MonthlyExpenseRow(label: "Utilities", today: max(inputs.monthlyUtilities, 0)),
            MonthlyExpenseRow(label: "Food & Groceries", today: max(inputs.monthlyFood, 0)),
            MonthlyExpenseRow(label: "Transportation", today: max(inputs.monthlyTransportation, 0)),
            MonthlyExpenseRow(label: "Healthcare", today: max(inputs.monthlyHealthcare, 0)),
            MonthlyExpenseRow(label: "Lifestyle", today: max(inputs.monthlyLifestyle, 0)),
            MonthlyExpenseRow(label: "Travel", today: max(inputs.monthlyTravel, 0)),
            MonthlyExpenseRow(label: "Other", today: max(inputs.monthlyOther, 0)),
            MonthlyExpenseRow(label: "Non-Monthly Costs (Avg)", today: max(inputs.annualNonMonthlyExpenses, 0) / 12)
        ]
        let plannedMonthlySpendToday = expenseRows.reduce(0) { $0 + $1.today }
        let annualSpendingToday = plannedMonthlySpendToday * 12

        let planned = project(inputs, spendingMultiplier: 1)

        let firstYearRetirementSpending = annualSpendingToday * inflationToRetirement
        let firstYearNetGap = max(firstYearRetirementSpending - socialSecurityStart - pensionStart, 0)
        let firstYearGrossWithdrawalNeed = firstYearNetGap / max(1 - retirementIncomeTaxRate, 0.01)
        let requiredNestEgg = firstYearGrossWithdrawalNeed / safeWithdrawalRate

        let targetGap = requiredNestEgg - planned.balanceAtRetirement
        let meetsWithdrawalRuleTarget = targetGap <= 0
        let retireReady = planned.runOutAge == nil

        let plannedMonthlySpendAtRetirement = firstYearRetirementSpending / 12
        let sustainableMultiplier = solveSustainableSpendingMultiplier(inputs)
        let sustainableMonthlySpend = plannedMonthlySpendToday * inflationToRetirement * sustainableMultiplier
        let sustainableAnnualSpend = sustainableMonthlySpend * 12
        let monthlyBudgetDelta = sustainableMonthlySpend - plannedMonthlySpendAtRetirement

        let monthlyBudgetRows = expenseRows.map { row in
            MonthlyBudgetRow(
                label: row.label,
                today: row.today,
                atRetirement: row.today * inflationToRetirement
            )
        }

        return RetirementAnalysis(
            assumptions: RetirementAssumptions(
                currentAge: currentAge,
                retirementAge: retirementAge,
                lifeExpectancy: lifeExpectancy,
                yearsToRetirement: yearsToRetirement,
                safeWithdrawalRate: safeWithdrawalRate
            ),
            timeline: planned.timeline,
            summary: RetirementSummary(
                balanceAtRetirement: planned.balanceAtRetirement,
                requiredNestEgg: requiredNestEgg,
                finalBalance: planned.finalBalance,
                targetGap: targetGap,
                retireReady: retireReady,
                meetsWithdrawalRuleTarget: meetsWithdrawalRuleTarget,
                runOutAge: planned.runOutAge,
                cumulativeContributions: planned.cumulativeContributions,
                cumulativeWithdrawals: planned.cumulativeWithdrawals,
                firstYearGap: firstYearNetGap,
                plannedMonthlySpendToday: plannedMonthlySpendToday,
                plannedMonthlySpendAtRetirement: plannedMonthlySpendAtRetirement,
                sustainableMonthlySpend: sustainableMonthlySpend,
                sustainableAnnualSpend: sustainableAnnualSpend,
                monthlyBudgetDelta: monthlyBudgetDelta,
                sustainableMultiplier: sustainableMultiplier,
                monthlyBudgetRows: monthlyBudgetRows,
                annualSpendingToday: annualSpendingToday,
                balanceAtRetirementToday: planned.balanceAtRetirement / inflationToRetirement,
                sustainableMonthlySpendToday: plannedMonthlySpendToday * sustainableMultiplier
            )
        )
    }
}


private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
    Swift.max(Swift.min(value, maximum), minimum)
}

private func annualToMonthlyRate(_ ratePct: Double) -> Double {
    let boundedRate = clamp(ratePct, min: -99, max: 1000) / 100
    return pow(1 + boundedRate, 1 / 12.0) - 1
}

private func annualRateMultiplier(_ ratePct: Double) -> Double {
    1 + (ratePct / 100)
}

private func mortgagePayment(principal: Double, annualRatePct: Double, termYears: Int) -> Double {
    let months = Swift.max(termYears * 12, 1)
    let monthlyRate = annualRatePct / 100 / 12

    if principal <= 0 { return 0 }
    if monthlyRate == 0 { return principal / Double(months) }

    return (principal * monthlyRate) / (1 - pow(1 + monthlyRate, -Double(months)))
}
