//
//  ReceiptFetcher.swift
//  Square Waves
//
//  Created by Alex Busman on 3/20/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import StoreKit

class ReceiptFetcher: NSObject, SKRequestDelegate {
    let receiptRefreshRequest = SKReceiptRefreshRequest()
    
    override init() {
        super.init()
        
        self.receiptRefreshRequest.delegate = self
    }
    
    func fetchReceipt() {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            NSLog("Unable to retrieve receipt URL")
            return
        }
        
        do {
            let reachable = try receiptUrl.checkResourceIsReachable()
            
            if !reachable {
                self.receiptRefreshRequest.start()
            }
        } catch {
            NSLog("Could not check if resource was reachable: \(error.localizedDescription)")
            self.receiptRefreshRequest.start()
        }
    }
    
    func requestDidFinish(_ request: SKRequest) {
        NSLog("Request finished successfully")
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        NSLog("Request failed with error \(error.localizedDescription)")
    }
}
