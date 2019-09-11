//
//  MetaDataChannel.swift
//  wehe
//
//  Created by Work on 4/25/19.
//  Copyright © 2019 Northeastern University. All rights reserved.
//

import Foundation
import Socket
import SSLService

class MetaDataChannel {

    // MARK: Properties

    let client: Socket
    let address: String
    let port: Int
    var isConnected = false

    static let objLength = 10
    static let connectionTimeout = 60 * 1000
    static let timeout = 2 * 60 * 1000

    init?(address: String, port: Int, family: Socket.ProtocolFamily) {
        self.address = address
        self.port = port

        do {
            client = try Socket.create(family: family, type: .stream, proto: .tcp)
            try client.setReadTimeout(value: UInt(1000 * 3))

            if Settings.https {
                let chainFilePath = String(Bundle.main.url(forResource: "ca", withExtension: "pfx")!.absoluteString.dropFirst(7))
                let config = SSLService.Configuration(withChainFilePath: chainFilePath, withPassword: Settings.pfxPassword, usingSelfSignedCerts: true, clientAllowsSelfSignedCertificates: true)
                client.delegate = try SSLService(usingConfiguration: config)
            }
        } catch let error {
            print(error)
            return nil
        }
    }

    func connect() throws {
        do {
            try client.connect(to: address, port: Int32(port), timeout: UInt(MetaDataChannel.connectionTimeout))
            isConnected = true
        } catch {
            isConnected = false
            throw SideChannelError.connectionError
        }
    }

    func sendMobileStats(settings: Settings, testID: String, historyCount: String) {
        do {
            let stats = Helper.getMobileStats(settings: settings)
            if settings.sendStats && stats != nil {
                let args = ["WillSendMobileStats", settings.randomID, historyCount, testID]
                try sendMessage(message: args.joined(separator: ";"))
                try sendMessage(message: stats!)
            }
        } catch {
            print("error sending mobile stats")
        }
    }

    func close() {
        guard isConnected else {
            return
        }
        isConnected = false
        client.close()
    }

    // MARK: Private methods
    private func sendMessage(message: String) throws {
        if !isConnected {
            throw SideChannelError.connectionError
        }

        let lengthMessage = String(format: "%010d", message.count)

        do {
            try client.write(from: lengthMessage)
            try client.write(from: message)
            //print("[message] -> " + message)
        } catch {
            throw SideChannelError.sendError
        }
    }
}
