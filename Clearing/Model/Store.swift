import StoreKit
import Observation

/// A purchasable plan shown on the paywall. `productID` maps to StoreKit / Products.storekit.
struct Plan: Identifiable, Equatable {
    let id: String
    let productID: String
    let title: String
    let priceLabel: String      // fallback when StoreKit products aren't loaded
    let periodLabel: String
    let subLabel: String?
    let trialLabel: String?
    let badge: String?
    let highlighted: Bool
}

enum Plans {
    static let annual = Plan(id: "annual", productID: "com.jarvis.clearing.annual",
                             title: "Yearly", priceLabel: "$29.99", periodLabel: "per year",
                             subLabel: "Just $0.58 / week", trialLabel: "7-day free trial",
                             badge: "BEST VALUE", highlighted: true)
    static let monthly = Plan(id: "monthly", productID: "com.jarvis.clearing.monthly",
                              title: "Monthly", priceLabel: "$4.99", periodLabel: "per month",
                              subLabel: nil, trialLabel: nil, badge: nil, highlighted: false)
    static let lifetime = Plan(id: "lifetime", productID: "com.jarvis.clearing.lifetime",
                               title: "Lifetime", priceLabel: "$49.99", periodLabel: "one time",
                               subLabel: "Pay once, yours forever", trialLabel: nil,
                               badge: nil, highlighted: false)
    static let all = [annual, monthly, lifetime]
}

/// Real StoreKit 2 billing. Works in the simulator via the bundled `Products.storekit`
/// configuration (referenced by the shared scheme). Falls back to a debug grant when no
/// products load (e.g. a headless `simctl` launch) so the demo flow always completes.
@MainActor
@Observable
final class Store {
    var products: [Product] = []
    var isPremium = false
    var isPurchasing = false
    var productsLoaded = false

    private let productIDs = [
        "com.jarvis.clearing.annual",
        "com.jarvis.clearing.monthly",
        "com.jarvis.clearing.lifetime",
    ]
    private let entitlementKey = "clearing.premium.v1"
    private var updatesTask: Task<Void, Never>?

    init() {
        isPremium = UserDefaults.standard.bool(forKey: entitlementKey)
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }

    /// Localized price from StoreKit when available, else the static fallback.
    func displayPrice(for plan: Plan) -> String {
        product(for: plan.productID)?.displayPrice ?? plan.priceLabel
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: productIDs)
            // keep our canonical ordering (annual, monthly, lifetime)
            products = productIDs.compactMap { id in loaded.first { $0.id == id } }
            productsLoaded = !products.isEmpty
        } catch {
            productsLoaded = false
        }
    }

    func purchase(_ plan: Plan) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        guard let product = product(for: plan.productID) else {
            // No StoreKit products (headless sim / config missing) — let the demo finish.
            #if DEBUG
            grantPremium()
            #endif
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    grantPremium()
                case .unverified(let transaction, _):
                    await transaction.finish()   // finish to stop redelivery, but don't grant
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // A real build would surface this; for now we simply stop the spinner.
        }
    }

    func restore() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil,
               productIDs.contains(transaction.productID) {
                active = true
            }
        }
        if active { grantPremium() } else { revokePremium() }
    }

    private func grantPremium() {
        guard !isPremium else { return }
        isPremium = true
        UserDefaults.standard.set(true, forKey: entitlementKey)
        Haptics.success()
    }

    private func revokePremium() {
        guard isPremium else { return }
        isPremium = false
        UserDefaults.standard.removeObject(forKey: entitlementKey)
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                switch update {
                case .verified(let transaction):
                    await transaction.finish()
                    await self?.refreshEntitlements()
                case .unverified(let transaction, _):
                    await transaction.finish()
                }
            }
        }
    }
}
