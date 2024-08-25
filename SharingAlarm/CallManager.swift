////
////  CallManager.swift
////  SharingAlarm
////
////  Created by 曹越程 on 2024/4/27.
////
//
//import CallKit
//import Foundation
//
//class CallManager: NSObject, CXProviderDelegate {
//    private let provider: CXProvider
//    
//    override init() {
//        let configuration = CXProviderConfiguration(localizedName: "My VoIP App")
//        configuration.includesCallsInRecents = false
//        configuration.supportsVideo = true
//        configuration.maximumCallsPerCallGroup = 1
//        configuration.supportedHandleTypes = [.phoneNumber]
//        
//        provider = CXProvider(configuration: configuration)
//        super.init()
//        provider.setDelegate(self, queue: nil) // Set delegate after initialization
//    }
//    
//    func reportIncomingCall(uuid: UUID, phoneNumber: String) {
//        print("Reporting Call")
//        let update = CXCallUpdate()
//        update.remoteHandle = CXHandle(type: .generic, value: phoneNumber)
//        update.supportsGrouping = true
//        update.hasVideo = false
//        
//        provider.reportNewIncomingCall(with: uuid, update: update) { error in
//            if let error = error {
//                print("Error reporting incoming call: \(error)")
//            } else {
//                print("Successfully reported incoming call")
//            }
//        }
//    }
//    
//    // MARK: - CXProviderDelegate methods
//    func providerDidReset(_ provider: CXProvider) {
//        // Handle provider reset
//    }
//    
//    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
//        print("Call answered")
//        // Handle answer call action
//        action.fulfill()
//    }
//    
//    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
//        print("Call ended")
//        // Handle end call action
//        action.fulfill()
//    }
//}
