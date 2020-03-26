//
//  IAPManager.swift
//  Backlogger
//
//  Created by Alex Busman on 2/3/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import StoreKit

/// Manages in-app purchases
class IAPManager: NSObject {
    /// Shared manager as singleton
    static let shared = IAPManager()
    /// Completion handler for products received
    var onReceiveProductsHandler: ((Result<[SKProduct], IAPManagerError>) -> Void)?
    /// Completion handler for buying products
    var onBuyProductHandler: ((Result<Bool, Error>) -> Void)?
    /// Count of how many purchases were restored
    var totalRestoredPurchases = 0

    /// Error codes
    enum IAPManagerError: Error {
        /// No product IDs found in plist
        case noProductIDsFound
        /// No products found from Apple
        case noProductsFound
        /// Payment was cancelled
        case paymentWasCancelled
        /// Failed to retrieve product
        case productRequestFailed
    }
    
    /**
     Private default constructor
     */
    private override init() {
        super.init()
    }
    
    /**
     Get product IDs from IAP_ProductIDs.plist
     - Returns: List of product IDs
     */
    func getProductIDs() -> [String]? {
        guard let url = Bundle.main.url(forResource: "IAP_ProductIDs", withExtension: "plist") else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let productIDs = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String] ?? []
            return productIDs
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    /**
     Get products list from Apple with given Product IDs
     - Parameter withHandler: Completion handler for products received
     */
    func getProducts(withHandler productsReceiveHandler: @escaping (_ result: Result<[SKProduct], IAPManagerError>) -> Void) {
        
        onReceiveProductsHandler = productsReceiveHandler
        
        guard let productIDs = getProductIDs() else {
            productsReceiveHandler(.failure(.noProductIDsFound))
            return
        }
        
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        
        request.delegate = self
        
        request.start()
    }
    
    /**
     Gets the formatted price for the current locale
     - Parameter for: Product to get price for from Apple
     - Returns: Formatted price
     */
    func getPriceFormatted(for product: SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
    
    /**
     Starts observing the SKPaymentQueue
     */
    func startObserving() {
        SKPaymentQueue.default().add(self)
    }
     
    /**
     Stops observing the SKPaymentQueue
     */
    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
    
    /**
     Check if account/device can make payments
     - Returns: Whether or not account/device can make payments
     */
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /**
     Attempts to buy the given product
     - Parameter product: Product to purchase
     - Parameter withHandler: Completion handler for buying products
     */
    func buy(product: SKProduct, withHandler handler: @escaping ((_ result: Result<Bool, Error>) -> Void)) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
     
        onBuyProductHandler = handler
    }
    
    /**
     Attempts to restore purchases
     - Parameter withHandler: Completion handler for buying products
     */
    func restorePurchases(withHandler handler: @escaping ((_ result: Result<Bool, Error>) -> Void)) {
        onBuyProductHandler = handler
        totalRestoredPurchases = 0
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension IAPManager.IAPManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noProductIDsFound: return "No In-App Purchase product identifiers were found."
        case .noProductsFound: return "No In-App Purchases were found."
        case .productRequestFailed: return "Unable to fetch available In-App Purchase products at the moment."
        case .paymentWasCancelled: return "In-App Purchase process was cancelled."
        }
    }
}

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        
        if products.count > 0 {
            onReceiveProductsHandler?(.success(products))
        } else {
            onReceiveProductsHandler?(.failure(.noProductsFound))
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        onReceiveProductsHandler?(.failure(.productRequestFailed))
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transaction) in
            switch transaction.transactionState {
            case .purchased:
                UserDefaults.standard.set(true, forKey: transaction.payment.productIdentifier)
                onBuyProductHandler?(.success(true))
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                UserDefaults.standard.set(true, forKey: transaction.payment.productIdentifier)
                totalRestoredPurchases += 1
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error as? SKError {
                    if error.code != .paymentCancelled {
                        onBuyProductHandler?(.failure(error))
                    } else {
                        onBuyProductHandler?(.failure(IAPManagerError.paymentWasCancelled))
                    }
                    print("IAP Error:", error.localizedDescription)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred, .purchasing: break
            @unknown default: break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if totalRestoredPurchases != 0 {
            onBuyProductHandler?(.success(true))
        } else {
            print("IAP: No purchases to restore!")
            onBuyProductHandler?(.success(false))
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let error = error as? SKError {
            if error.code != .paymentCancelled {
                print("IAP Restore Error:", error.localizedDescription)
                onBuyProductHandler?(.failure(error))
            } else {
                onBuyProductHandler?(.failure(IAPManagerError.paymentWasCancelled))
            }
        }
    }
}
