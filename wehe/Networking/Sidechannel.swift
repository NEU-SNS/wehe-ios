//
//  Sidechannel.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/13/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
// Side channel between the client and the server to pass replay information and identification

import Foundation
// import SwiftSocket
import SwiftyJSON
import Socket
import SSLService

class Sidechannel {

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
            try client.connect(to: address, port: Int32(port), timeout: UInt(Sidechannel.connectionTimeout))
            isConnected = true
        } catch {
            isConnected = false
            throw SideChannelError.connectionError
        }
    }

    func declareID(replayName: String, endOfTest: String, testID: String, realIP: String, settings: Settings, historyCount: Int) throws {
        var appVersion: String
        if let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let bundlebuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                appVersion = bundleVersion + bundlebuild
            } else {
                appVersion = bundleVersion
            }
        } else {
            appVersion = "1.0"
        }

        let messageArray = [settings.randomID, testID, replayName, settings.extraString, String(historyCount), endOfTest, realIP, appVersion]
        let message = messageArray.joined(separator: ";")

        do {
           try sendMessage(message: message)
        } catch {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.declearIDError)
        }
    }

    func sendChangeSpec(mpacNum: Int, action: String, spec: String) throws {
        let args = [String(mpacNum), action, spec]
        let message = "[" + args.joined(separator: ", ") + "]"
        do {
            try sendMessage(message: message)
        } catch {
            throw ReplayError.sideChannelError(reason: "Error sending changes specification")
        }
    }

    func askForPermission() throws -> [String] {
        do {
            let permission = try receiveMessage()
            return permission.components(separatedBy: ";")
        } catch {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.readPermissionError)
        }
    }

    func sendIperf() throws {
        do {
            try sendMessage(message: "NoIperf")
        } catch {
            throw ReplayError.sideChannelError(reason: "Error sending Iperf")
        }
    }

    func sendMobileStats(settings: Settings) throws {
        do {
            let stats = Helper.getMobileStats(settings: settings)
            if settings.sendStats && stats != nil {
                try sendMessage(message: "WillSendMobileStats")
                try sendMessage(message: stats!)
            } else {
                try sendMessage(message: "NoMobileStats")
            }
        } catch {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.mobileStatError)
        }
    }

    func receivePortMapping() throws -> PortMapping {
        do {
            let mapping = try receiveMessage()
            guard let dataFromString = mapping.data(using: .utf8, allowLossyConversion: false) else {
                throw SideChannelError.receiveError(reason: LocalizedStrings.errors.readPortMappingError)
            }
            let json = try JSON(data: dataFromString)
            if let portMapping = PortMapping(blob: json) {
                return portMapping
            } else {
                throw SideChannelError.receiveError(reason: "Error reading port mapping from server")
            }

        } catch let error {
            print(error)
            throw ReplayError.sideChannelError(reason: "Error reading port mapping from server")
        }
    }

    func receiveSenderCount() throws -> Int {
        do {
            let resp = try receiveMessage()
            guard let senderCount = Int(resp) else {
                throw SideChannelError.receiveError(reason: "Error parsing sender count")
            }

            return senderCount
        }
    }

    func getUDPInformation() throws -> [String] {
        do {
            let resp = try receiveMessage(timeout: 10)
            return resp.components(separatedBy: ";")
        } catch {
            throw SideChannelError.receiveError(reason: "Error receiving UDP notifier status")
        }
    }

    func sendDone(duration: Double) throws {
        do {
            try sendMessage(message: "DONE;" + String(duration))
        } catch {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.completionMessageError)
        }
    }

    func sendJitter(id: String) throws {
        do {
            try sendMessage(message: "NoJitter;" + id)
        } catch {
            throw ReplayError.sideChannelError(reason: "Error sending jitter statistics")
        }
    }

    func sendTimeSlices(slices: [Double: Double]) throws {
        var averageThroughputs = [Double]()
        var timeSlices = [Double]()

        for (k, _) in slices {
            timeSlices.append(k)
        }

        timeSlices.sort()

        for slice in timeSlices {
            averageThroughputs.append(slices[slice]!)
        }

        var output = [[Double]]()
        output.append(averageThroughputs)
        output.append(timeSlices)
        let json = JSON(output)

        do {
            try sendMessage(message: json.rawString()!.removingWhitespaces())
        } catch {
            throw ReplayError.sideChannelError(reason: "Error sending time slices")
        }
    }

    func getResult() throws {
        do {
            try sendMessage(message: "Result;No")
            _ = try receiveMessage()
        } catch is SideChannelError {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.receiveResultError)
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

    private func receiveMessage(length: Int = objLength, timeout: Int = timeout) throws -> String {
        do {
            let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: length + 1)
            buffer.initialize(repeating: 0, count: length + 1)

            defer {
                buffer.deinitialize(count: length + 1)
                buffer.deallocate()
            }
            var read = try client.read(into: buffer, bufSize: length, truncate: true)

            guard read == length else {
                print("Read only " + String(read) + " bytes")
                throw SideChannelError.receiveError(reason: "did not receive enough length bytes from sidechannel")
            }

            guard let parsedLength = Int(String(cString: buffer)) else {
                throw SideChannelError.receiveError(reason: "error parsing received length value")
            }

            let objectBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: parsedLength + 1)
            objectBuffer.initialize(repeating: 0, count: parsedLength + 1)

            defer {
                objectBuffer.deinitialize(count: parsedLength + 1)
                objectBuffer.deallocate()
            }
            
            read = try client.read(into: objectBuffer, bufSize: parsedLength, truncate: true)
            while read < parsedLength {
                // large packet, needs to read from socket multiple times
                let newRead = try client.read(into: objectBuffer, bufSize: parsedLength, truncate: true)
                read += newRead
            }
            guard read == parsedLength else {
                throw SideChannelError.receiveError(reason: "did not receive enough object bytes from sidechannel")
            }

            return String(cString: objectBuffer)
        } catch let error {
            print(error)
            throw SideChannelError.receiveError(reason: "error reading sidechannel data")
        }
    }
}

enum SideChannelError: Error {
    case connectionError
    case sendError
    case receiveError(reason: String)
}
