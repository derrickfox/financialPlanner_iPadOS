import Foundation

enum RentVsBuyCalculator {
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
        let hoaStart = max(inputs.hoaMonthly, 0)
        let closingCostRate = max(inputs.closingCostPct, 0) / 100
        let sellingCostRate = clamp(inputs.sellingCostPct, min: 0, max: 100) / 100
        let appreciationPct = inputs.homeAppreciationPct
        let investmentReturnPct = inputs.investmentReturnPct
        let inflationPct = inputs.annualInflationPct

        let downPayment = homePrice * downPaymentRate
        let closingCosts = homePrice * closingCostRate
        let mortgagePrincipal = homePrice - downPayment
        let monthlyMortgagePayment = mortgagePayment(
            principal: mortgagePrincipal,
            annualRatePct: mortgageRatePct,
            termYears: loanTermYears
        )
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
        var renterOutflow = 0.0
        var renterInvestment = downPayment + closingCosts

        var timeline: [RentVsBuyPoint] = []
        var breakEvenYear: Double?

        for month in 1...(years * 12) {
            if month > 1 {
                rent *= (1 + monthlyRentGrowth)
                rentersInsurance *= (1 + monthlyInflation)
                homeInsurance *= (1 + monthlyInflation)
                hoa *= (1 + monthlyInflation)
                homeValue *= (1 + monthlyHomeGrowth)
            }

            renterInvestment *= (1 + monthlyInvestmentGrowth)

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

            let ownerMonthlyCost = mortgagePaymentThisMonth
                + propertyTaxThisMonth
                + maintenanceThisMonth
                + homeInsurance
                + hoa
            let renterMonthlyCost = rent + rentersInsurance

            ownerOutflow += ownerMonthlyCost
            renterOutflow += renterMonthlyCost

            renterInvestment += ownerMonthlyCost - renterMonthlyCost

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

    static func compute(_ inputs: RetirementInputs) -> RetirementAnalysis {
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
        let safeWithdrawalRate = clamp(inputs.safeWithdrawalRatePct, min: 0.5, max: 15) / 100

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

        let firstYearRetirementSpending = annualSpendingToday * inflationToRetirement
        var retirementSpending = firstYearRetirementSpending

        var cumulativeContributions = 0.0
        var cumulativeWithdrawals = 0.0
        var runOutAge: Int?

        let firstYearNetGap = max(firstYearRetirementSpending - socialSecurity - pension, 0)
        let firstYearGrossWithdrawalNeed = firstYearNetGap / max(1 - retirementIncomeTaxRate, 0.01)
        let requiredNestEgg = firstYearGrossWithdrawalNeed / safeWithdrawalRate

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
                if shortfall > 0 {
                    let grossWithdrawal = shortfall / max(1 - retirementIncomeTaxRate, 0.01)
                    withdrawalThisYear = grossWithdrawal
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

                if runOutAge == nil, balance <= 0 {
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

        let finalBalance = timeline.last?.balance ?? 0
        let targetGap = requiredNestEgg - balanceAtRetirement
        let retireReady = targetGap <= 0

        let plannedMonthlySpendAtRetirement = firstYearRetirementSpending / 12
        let sustainableGrossWithdrawal = balanceAtRetirement * safeWithdrawalRate
        let sustainableNetPortfolioSpend = sustainableGrossWithdrawal * (1 - retirementIncomeTaxRate)
        let sustainableAnnualSpend = socialSecurityStart + pensionStart + sustainableNetPortfolioSpend
        let sustainableMonthlySpend = sustainableAnnualSpend / 12
        let monthlyBudgetDelta = sustainableMonthlySpend - plannedMonthlySpendAtRetirement
        let monthlyGapAtRetirement = firstYearNetGap / 12

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
            timeline: timeline,
            summary: RetirementSummary(
                balanceAtRetirement: balanceAtRetirement,
                requiredNestEgg: requiredNestEgg,
                finalBalance: finalBalance,
                targetGap: targetGap,
                retireReady: retireReady,
                runOutAge: runOutAge,
                cumulativeContributions: cumulativeContributions,
                cumulativeWithdrawals: cumulativeWithdrawals,
                monthlyGapAtRetirement: monthlyGapAtRetirement,
                firstYearGap: firstYearNetGap,
                plannedMonthlySpendToday: plannedMonthlySpendToday,
                plannedMonthlySpendAtRetirement: plannedMonthlySpendAtRetirement,
                sustainableMonthlySpend: sustainableMonthlySpend,
                sustainableAnnualSpend: sustainableAnnualSpend,
                monthlyBudgetDelta: monthlyBudgetDelta,
                monthlyBudgetRows: monthlyBudgetRows,
                annualSpendingToday: annualSpendingToday
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
