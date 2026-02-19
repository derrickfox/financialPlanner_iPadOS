import Foundation

enum CalculatorMode: String, Codable {
    case rentVsBuy
    case retirement
}

struct RentVsBuyInputs: Codable, Equatable {
    var years: Double = 10
    var monthlyRent: Double = 2200
    var rentIncreasePct: Double = 3
    var rentersInsuranceMonthly: Double = 22
    var homePrice: Double = 500000
    var downPaymentPct: Double = 20
    var mortgageRatePct: Double = 6.5
    var loanTermYears: Double = 30
    var propertyTaxPct: Double = 1.2
    var homeInsuranceAnnual: Double = 1800
    var maintenancePct: Double = 1
    var hoaMonthly: Double = 150
    var closingCostPct: Double = 3
    var sellingCostPct: Double = 6
    var homeAppreciationPct: Double = 3
    var investmentReturnPct: Double = 5
    var annualInflationPct: Double = 2
}

struct RetirementInputs: Codable, Equatable {
    var currentAge: Double = 35
    var retirementAge: Double = 67
    var lifeExpectancy: Double = 92
    var currentSavings: Double = 120000
    var annualContribution: Double = 18000
    var employerMatchAnnual: Double = 5000
    var contributionGrowthPct: Double = 2
    var preRetirementReturnPct: Double = 7
    var postRetirementReturnPct: Double = 5
    var investmentDragPct: Double = 1

    var monthlyHousing: Double = 1800
    var monthlyUtilities: Double = 350
    var monthlyFood: Double = 700
    var monthlyTransportation: Double = 450
    var monthlyHealthcare: Double = 500
    var monthlyLifestyle: Double = 550
    var monthlyTravel: Double = 300
    var monthlyOther: Double = 300
    var annualNonMonthlyExpenses: Double = 6000

    var socialSecurityAnnual: Double = 32000
    var pensionAnnual: Double = 0
    var benefitIncreasePct: Double = 2
    var inflationPct: Double = 2.5
    var retirementIncomeTaxPct: Double = 12
    var safeWithdrawalRatePct: Double = 4
}

enum RentVsBuyFieldKey: String, Hashable {
    case years
    case monthlyRent
    case rentIncreasePct
    case rentersInsuranceMonthly
    case homePrice
    case downPaymentPct
    case mortgageRatePct
    case loanTermYears
    case propertyTaxPct
    case homeInsuranceAnnual
    case maintenancePct
    case hoaMonthly
    case closingCostPct
    case sellingCostPct
    case homeAppreciationPct
    case investmentReturnPct
    case annualInflationPct
}

enum RetirementFieldKey: String, Hashable {
    case currentAge
    case retirementAge
    case lifeExpectancy
    case currentSavings
    case annualContribution
    case employerMatchAnnual
    case contributionGrowthPct
    case preRetirementReturnPct
    case postRetirementReturnPct
    case investmentDragPct
    case monthlyHousing
    case monthlyUtilities
    case monthlyFood
    case monthlyTransportation
    case monthlyHealthcare
    case monthlyLifestyle
    case monthlyTravel
    case monthlyOther
    case annualNonMonthlyExpenses
    case socialSecurityAnnual
    case pensionAnnual
    case benefitIncreasePct
    case inflationPct
    case retirementIncomeTaxPct
    case safeWithdrawalRatePct
}

struct FieldDescriptor<Key: RawRepresentable & Hashable>: Identifiable where Key.RawValue == String {
    let key: Key
    let label: String
    let suffix: String
    let range: ClosedRange<Double>?
    let step: Double

    var id: String { key.rawValue }

    init(
        key: Key,
        label: String,
        suffix: String,
        range: ClosedRange<Double>? = nil,
        step: Double
    ) {
        self.key = key
        self.label = label
        self.suffix = suffix
        self.range = range
        self.step = step
    }
}

struct FieldGroup<Key: RawRepresentable & Hashable>: Identifiable where Key.RawValue == String {
    let id: String
    let title: String
    let fields: [FieldDescriptor<Key>]
}

let rentVsBuyFieldGroups: [FieldGroup<RentVsBuyFieldKey>] = [
    FieldGroup(
        id: "time",
        title: "Time Horizon",
        fields: [
            FieldDescriptor(key: .years, label: "Comparison Horizon", suffix: "years", range: 1...50, step: 1)
        ]
    ),
    FieldGroup(
        id: "renting",
        title: "Renting Assumptions",
        fields: [
            FieldDescriptor(key: .monthlyRent, label: "Starting Monthly Rent", suffix: "$/mo", range: 0...50000, step: 50),
            FieldDescriptor(key: .rentIncreasePct, label: "Annual Rent Increase", suffix: "%", range: -20...30, step: 0.1),
            FieldDescriptor(key: .rentersInsuranceMonthly, label: "Renter Insurance", suffix: "$/mo", range: 0...2000, step: 5)
        ]
    ),
    FieldGroup(
        id: "buying",
        title: "Buying Assumptions",
        fields: [
            FieldDescriptor(key: .homePrice, label: "Home Purchase Price", suffix: "$", range: 0...10000000, step: 5000),
            FieldDescriptor(key: .downPaymentPct, label: "Down Payment", suffix: "%", range: 0...100, step: 1),
            FieldDescriptor(key: .mortgageRatePct, label: "Mortgage Rate", suffix: "%", range: 0...20, step: 0.05),
            FieldDescriptor(key: .loanTermYears, label: "Mortgage Term", suffix: "years", range: 1...40, step: 1),
            FieldDescriptor(key: .propertyTaxPct, label: "Property Tax", suffix: "%/yr", range: 0...8, step: 0.1),
            FieldDescriptor(key: .homeInsuranceAnnual, label: "Home Insurance", suffix: "$/yr", range: 0...50000, step: 100),
            FieldDescriptor(key: .maintenancePct, label: "Maintenance", suffix: "%/yr", range: 0...10, step: 0.1),
            FieldDescriptor(key: .hoaMonthly, label: "HOA Fees", suffix: "$/mo", range: 0...5000, step: 25),
            FieldDescriptor(key: .closingCostPct, label: "Closing Costs", suffix: "% of price", range: 0...15, step: 0.25),
            FieldDescriptor(key: .sellingCostPct, label: "Selling Costs", suffix: "% of value", range: 0...15, step: 0.25),
            FieldDescriptor(key: .homeAppreciationPct, label: "Home Appreciation", suffix: "%/yr", range: -20...20, step: 0.1)
        ]
    ),
    FieldGroup(
        id: "financial",
        title: "Financial Assumptions",
        fields: [
            FieldDescriptor(key: .investmentReturnPct, label: "Investment Return (Renter)", suffix: "%/yr", range: -20...20, step: 0.1),
            FieldDescriptor(key: .annualInflationPct, label: "Inflation on Recurring Costs", suffix: "%/yr", range: -5...20, step: 0.1)
        ]
    )
]

let retirementFieldGroups: [FieldGroup<RetirementFieldKey>] = [
    FieldGroup(
        id: "timeline",
        title: "Timeline",
        fields: [
            FieldDescriptor(key: .currentAge, label: "Current Age", suffix: "years", range: 18...90, step: 1),
            FieldDescriptor(key: .retirementAge, label: "Retirement Age", suffix: "years", range: 40...95, step: 1),
            FieldDescriptor(key: .lifeExpectancy, label: "Life Expectancy", suffix: "years", range: 55...110, step: 1)
        ]
    ),
    FieldGroup(
        id: "savings",
        title: "Savings & Growth",
        fields: [
            FieldDescriptor(key: .currentSavings, label: "Current Retirement Savings", suffix: "$", range: 0...50000000, step: 5000),
            FieldDescriptor(key: .annualContribution, label: "Annual Contribution", suffix: "$/yr", range: 0...500000, step: 500),
            FieldDescriptor(key: .employerMatchAnnual, label: "Employer Match", suffix: "$/yr", range: 0...500000, step: 500),
            FieldDescriptor(key: .contributionGrowthPct, label: "Contribution Growth", suffix: "%/yr", range: -10...20, step: 0.1),
            FieldDescriptor(key: .preRetirementReturnPct, label: "Return Before Retirement", suffix: "%/yr", range: -20...25, step: 0.1),
            FieldDescriptor(key: .postRetirementReturnPct, label: "Return During Retirement", suffix: "%/yr", range: -20...20, step: 0.1),
            FieldDescriptor(key: .investmentDragPct, label: "Fees / Tax Drag", suffix: "%/yr", range: 0...8, step: 0.1)
        ]
    ),
    FieldGroup(
        id: "budget",
        title: "Monthly Expense Budget (Today)",
        fields: [
            FieldDescriptor(key: .monthlyHousing, label: "Housing", suffix: "$/mo", range: 0...20000, step: 50),
            FieldDescriptor(key: .monthlyUtilities, label: "Utilities", suffix: "$/mo", range: 0...5000, step: 25),
            FieldDescriptor(key: .monthlyFood, label: "Food & Groceries", suffix: "$/mo", range: 0...10000, step: 25),
            FieldDescriptor(key: .monthlyTransportation, label: "Transportation", suffix: "$/mo", range: 0...10000, step: 25),
            FieldDescriptor(key: .monthlyHealthcare, label: "Healthcare", suffix: "$/mo", range: 0...15000, step: 25),
            FieldDescriptor(key: .monthlyLifestyle, label: "Lifestyle", suffix: "$/mo", range: 0...15000, step: 25),
            FieldDescriptor(key: .monthlyTravel, label: "Travel", suffix: "$/mo", range: 0...15000, step: 25),
            FieldDescriptor(key: .monthlyOther, label: "Other", suffix: "$/mo", range: 0...15000, step: 25),
            FieldDescriptor(key: .annualNonMonthlyExpenses, label: "Annual Non-Monthly Costs", suffix: "$/yr", range: 0...1000000, step: 250)
        ]
    ),
    FieldGroup(
        id: "cashflow",
        title: "Retirement Cash Flow",
        fields: [
            FieldDescriptor(key: .socialSecurityAnnual, label: "Social Security at Retirement", suffix: "$/yr", range: 0...200000, step: 500),
            FieldDescriptor(key: .pensionAnnual, label: "Pension at Retirement", suffix: "$/yr", range: 0...200000, step: 500),
            FieldDescriptor(key: .benefitIncreasePct, label: "Income COLA (SS + Pension)", suffix: "%/yr", range: -5...10, step: 0.1),
            FieldDescriptor(key: .inflationPct, label: "Inflation", suffix: "%/yr", range: -2...20, step: 0.1),
            FieldDescriptor(key: .retirementIncomeTaxPct, label: "Retirement Income Tax Rate", suffix: "%", range: 0...95, step: 0.5),
            FieldDescriptor(key: .safeWithdrawalRatePct, label: "Safe Withdrawal Rule", suffix: "%", range: 0.5...15, step: 0.1)
        ]
    )
]

struct RentVsBuyPoint: Identifiable {
    let year: Int
    let ownerNetCost: Double
    let renterNetCost: Double
    let ownerOutflow: Double
    let renterOutflow: Double
    let ownerEquity: Double
    let renterInvestment: Double

    var id: Int { year }
}

struct RentVsBuySummary {
    let winner: String
    let breakEvenYear: Double?
    let costDifference: Double
    let ownerNetCost: Double
    let renterNetCost: Double
    let ownerOutflow: Double
    let renterOutflow: Double
    let ownerEquity: Double
    let renterInvestment: Double
}

struct RentVsBuyAssumptions {
    let years: Int
    let monthlyMortgagePayment: Double
}

struct RentVsBuyAnalysis {
    let assumptions: RentVsBuyAssumptions
    let timeline: [RentVsBuyPoint]
    let summary: RentVsBuySummary
}

struct RetirementPoint: Identifiable {
    let age: Int
    let isRetired: Bool
    let balance: Double
    let contribution: Double
    let withdrawal: Double
    let retirementIncome: Double
    let retirementSpending: Double

    var id: Int { age }
}

struct MonthlyBudgetRow: Identifiable {
    let label: String
    let today: Double
    let atRetirement: Double

    var id: String { label }
}

struct RetirementSummary {
    let balanceAtRetirement: Double
    let requiredNestEgg: Double
    let finalBalance: Double
    let targetGap: Double
    let retireReady: Bool
    let runOutAge: Int?
    let cumulativeContributions: Double
    let cumulativeWithdrawals: Double
    let monthlyGapAtRetirement: Double
    let firstYearGap: Double
    let plannedMonthlySpendToday: Double
    let plannedMonthlySpendAtRetirement: Double
    let sustainableMonthlySpend: Double
    let sustainableAnnualSpend: Double
    let monthlyBudgetDelta: Double
    let monthlyBudgetRows: [MonthlyBudgetRow]
    let annualSpendingToday: Double
}

struct RetirementAssumptions {
    let currentAge: Int
    let retirementAge: Int
    let lifeExpectancy: Int
    let yearsToRetirement: Int
    let safeWithdrawalRate: Double
}

struct RetirementAnalysis {
    let assumptions: RetirementAssumptions
    let timeline: [RetirementPoint]
    let summary: RetirementSummary
}
