import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var mode: CalculatorMode
    @State private var rentVsBuyInputs: RentVsBuyInputs
    @State private var retirementInputs: RetirementInputs

    init() {
        let persisted = AppStateStore.load()
        _mode = State(initialValue: persisted.mode)
        _rentVsBuyInputs = State(initialValue: persisted.rentVsBuyInputs)
        _retirementInputs = State(initialValue: persisted.retirementInputs)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if mode == .rentVsBuy {
                        RentVsBuyView(
                            inputs: $rentVsBuyInputs,
                            onSwitch: { mode = .retirement }
                        )
                    } else {
                        RetirementView(
                            inputs: $retirementInputs,
                            onSwitch: { mode = .rentVsBuy }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: 1320)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.light)
        .onChange(of: mode) { _, _ in
            persistState()
        }
        .onChange(of: rentVsBuyInputs) { _, _ in
            persistState()
        }
        .onChange(of: retirementInputs) { _, _ in
            persistState()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                persistState()
            }
        }
    }

    private func persistState() {
        AppStateStore.save(
            mode: mode,
            rentVsBuyInputs: rentVsBuyInputs,
            retirementInputs: retirementInputs
        )
    }
}
