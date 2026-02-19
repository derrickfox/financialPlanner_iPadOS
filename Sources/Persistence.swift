import Foundation

struct PersistedAppState: Codable, Equatable {
    var mode: CalculatorMode = .rentVsBuy
    var rentVsBuyInputs = RentVsBuyInputs()
    var retirementInputs = RetirementInputs()
}

enum AppStateStore {
    private static let key = "com.derrickfox.rentvsbuy.ipad.persistedState"

    static func load() -> PersistedAppState {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let state = try? JSONDecoder().decode(PersistedAppState.self, from: data)
        else {
            return PersistedAppState()
        }
        return state
    }

    static func save(
        mode: CalculatorMode,
        rentVsBuyInputs: RentVsBuyInputs,
        retirementInputs: RetirementInputs
    ) {
        save(
            PersistedAppState(
                mode: mode,
                rentVsBuyInputs: rentVsBuyInputs,
                retirementInputs: retirementInputs
            )
        )
    }

    static func save(_ state: PersistedAppState) {
        guard let data = try? JSONEncoder().encode(state) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}
