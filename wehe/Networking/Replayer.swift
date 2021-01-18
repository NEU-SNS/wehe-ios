//
//  TCPReplayer.swift
//  wehe
//
//  Created by Kirill Voloshin on 10/12/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
//  Responsible for running a single replay

import Foundation
// import SwiftSocket
import Socket

class Replayer {
    let settings: Settings
    let replayRunner: ReplayRunner
    let replay: Replay
    let replayType: ReplayType
    let deviceIP: String
    let historyCount: Int
    let app: App
    let serverIP: String
    let family: Socket.ProtocolFamily

    let sidechannel: Sidechannel
//    let metaDatachannel: MetaDataChannel?
    var error = false
    var forceQuit = false

    var readBufferLength = 0

    let tcpTimeout = 2
    let socketConnectTimeout: UInt = 5 * 1000
    let socketReadTimeout: UInt = 2 * 1000
    let socketWriteTimeout: UInt = 2 * 1000
    let udpBuffer = 4096

    // DEBUG
    var fellBehind: Int = 0
    var sentOnTime: Int = 0

    init(settings: Settings, deviceIP: String, replay: Replay, replayType: ReplayType, replayRunner: ReplayRunner, app: App, serverIP: String?) throws {
        self.settings = settings
        self.deviceIP = deviceIP
        self.replay = replay
        self.replayType = replayType
        self.replayRunner = replayRunner
        self.historyCount = app.historyCount ?? 0
        self.app = app
        self.serverIP = serverIP ?? settings.serverIP
        self.family = Helper.getIPProtocol(ip: self.serverIP)
        let port = Settings.https ? settings.httpsPort : settings.port

        guard let sidechannel = Sidechannel(address: self.serverIP, port: port, family: family) else {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.sideChannelCreationError)
        }

//        self.metaDatachannel = MetaDataChannel(address: Settings.metaDataserver, port: port, family: family)

        self.sidechannel = sidechannel

        do {
            try sidechannel.connect()
        } catch is SideChannelError {
            self.error = true
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.sideChannelConnectionError)
        } catch let error {
            self.error = true
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.sideChannelError)
        }
//        do {
//            try metaDatachannel?.connect()
//        } catch is SideChannelError {
//            print("error connecting to metadata server")
//        } catch let error {
//            print(error)
//            print("error connecting to metadata server")
//        }
    }

    func cancel() {
        forceQuit = true
        sidechannel.close()
    }

    func runReplay(dpiTestID: Int = -1) {
        var endOfTest: String
        var testID: String

        switch replayType {
        case .original:
            testID = "0"
            if app.replaysRan.contains(.random) {
                endOfTest = "False"
            } else {
                endOfTest = "True"
            }
            
        case .random:
            testID = "1"
            if app.replaysRan.contains(.original) {
                endOfTest = "False"
            } else {
                endOfTest = "True"
            }
        case .dpi:
            testID = String(dpiTestID)
            endOfTest = "False"
        }

        do {
            try sidechannel.declareID(replayName: replay.name, endOfTest: endOfTest, testID: testID, realIP: deviceIP, settings: settings, historyCount: historyCount)
            try sidechannel.sendChangeSpec(mpacNum: -1, action: "null", spec: "null")

            Helper.runOnUIThread {
                self.replayRunner.updateStatus(newStatus: .askingForPermission)
//                self.replayRunner.updateProgress(value: 0.2)
            }

            let permissions = try sidechannel.askForPermission()
            Helper.runOnUIThread {
//                self.replayRunner.updateProgress(value: 0.5)
            }

            guard permissions.count == 3 || permissions.count == 2 else {
                throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.malformedPermissionError)
            }

            let permissionError = permissions[0]
            let permissionData = permissions[1]

            if permissionError == "0" {
                switch permissionData {
                case "1":
                    throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.unknownReplayError)
                case "2":
                    throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.clientIPError)
                case "3":
                    throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.serverResourcesError)
                default:
                    throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.permissionError)
                }
            } else if permissionError == "1" {
                Helper.runOnUIThread {
                    self.replayRunner.updateStatus(newStatus: .receivedPermission)
                }

            } else {
                throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.unknownPermissionError)
            }

            guard let numberOfTimeSlices = Double(permissions[2]) else {
                throw ReplayError.sideChannelError(reason: "Error parsing number of time slices")
            }

            try sidechannel.sendIperf()
            try sidechannel.sendMobileStats(settings: settings)
//            metaDatachannel?.sendMobileStats(settings: settings, testID: testID, historyCount: String(historyCount))
//            metaDatachannel?.close()

            Helper.runOnUIThread {
//                self.replayRunner.updateProgress(value: 0.7)

                self.replayRunner.updateStatus(newStatus: .receivingPortMapping)
            }

            let portMapping = try sidechannel.receivePortMapping()
            sleep(1)
            let udpSenderCount = try sidechannel.receiveSenderCount() // only udp replays care about this

            Helper.runOnUIThread {
                self.replayRunner.updateProgress(value: 0)
                switch self.replayType {
                case .original:
                    if self.app.isPortTest {
                        self.replayRunner.updateStatus(newStatus: .testPortReplay)
                    } else {
                        self.replayRunner.updateStatus(newStatus: .originalReplay)
                    }
                case .random:
                    if self.app.isPortTest {
                        self.replayRunner.updateStatus(newStatus: .baselinePortReplay)
                    } else {
                        self.replayRunner.updateStatus(newStatus: .randomReplay)
                    }
                case .dpi:      self.replayRunner.updateStatus(newStatus: .originalReplay)
                }
            }

            switch replay.type {
            case .tcp:
                if self.app.isPortTest {
                    let portTestTimeout = 30
                    try runTCPReplay(portMapping: portMapping, clientIP: permissionData, numberOfTimeSlices: numberOfTimeSlices, testTimeout: Double(portTestTimeout))
                } else {
                    let appTestTimeout = 45
                    try runTCPReplay(portMapping: portMapping, clientIP: permissionData, numberOfTimeSlices: numberOfTimeSlices, testTimeout: Double(appTestTimeout))
                }
            case .udp:
                let appTestTimeout = 40
                try self.runUDPReplay(portMapping: portMapping, clientIP: permissionData, senderCount: udpSenderCount, numberOfTimeSlices: numberOfTimeSlices, testTimeout: Double(appTestTimeout))
            }

        } catch let error as ReplayError {
            Helper.runOnUIThread {
                self.replayRunner.replayFailed(error: error)
            }
        } catch let error {
            print(error.localizedDescription)
            Helper.runOnUIThread {
                self.replayRunner.replayFailed(error: ReplayError.otherError(reason: LocalizedStrings.errors.replayFailedError))
            }
        }
    }

    // MARK: Private methods
    private func runUDPReplay(portMapping: PortMapping, clientIP: String, senderCount: Int, numberOfTimeSlices: Double, testTimeout: Double) throws {

        defer {
            sidechannel.close()
        }

        let firstPacket = replay.packets[0]
        let ipAndPort = firstPacket.cSPair.components(separatedBy: "-")[1]
        //ipv6
        let ip: String
        let port: String
        if ipAndPort.contains(":") {
            ip = ipAndPort.components(separatedBy: ".")[0]
            port = ipAndPort.components(separatedBy: ".")[1]
        } else {
            ip = ipAndPort.components(separatedBy: ".")[0..<4].joined(separator: ".")
            port = ipAndPort.components(separatedBy: ".")[4]
        }

        // figure out the ip and port for the socket
        guard var spPair = portMapping.getPortMapping(ip: ip, port: port, prot: .udp) else {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.portMappingError)
        }

        if spPair.ip == "" {
            spPair.ip = settings.serverIP
        }

        var client: Socket

        do {
            client = try Socket.create(family: family, type: .datagram, proto: .udp)

            try client.setReadTimeout(value: socketReadTimeout)
            try client.setWriteTimeout(value: socketWriteTimeout)
            //try client.connect(to: spPair.ip, port: spPair.port, timeout: socketConnectTimeout)
        } catch let error {
            print("Error establishing UDP socket \(error)")
            throw ReplayError.connectionBlockError(reason: LocalizedStrings.errors.connectionBlockError)
        }

        defer {
            client.close()
        }

        // Notifier thread
        let group = DispatchGroup()
        var keepReceiving = true
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            defer {
                print("Notifier done")
                group.leave()
            }

            var inProgress = 0
            while true {
                do {
                    let udpInfo = try self.sidechannel.getUDPInformation()
                    switch udpInfo[0] {
                    case "STARTED": inProgress += 1
                    case "DONE":
                        inProgress -= 1
                        if inProgress == 0 {
                            return
                        }

                    default: print("[Notifier] Unrecognized udp info " + udpInfo[0])
                    }
                } catch {
                    print("[Notifier] notifier error")
                }
                if self.forceQuit || !keepReceiving || (inProgress == 0) {
                    print("Returning 2")
                    return
                }
            }
        }

        // Analyzer Thread
        var keepAnalyzing = true
        var timeSlices: [Double: Int] = [:]
        let timePerSlice = Double(min(app.time, testTimeout)) / numberOfTimeSlices
        let semaphore = DispatchSemaphore(value: 1)
        let analyzerWaitGroup = DispatchGroup()

        analyzerWaitGroup.enter()
        Helper.runOnUIThread {
            var ran = 0
            _ = Timer.scheduledTimer(withTimeInterval: timePerSlice, repeats: true) { timer in
                ran += 1

                let timeSlice = Double(ran) * timePerSlice
                semaphore.wait()
                timeSlices[timeSlice] = self.readBufferLength
                self.readBufferLength = 0
                semaphore.signal()

                if !keepAnalyzing || self.forceQuit {
                    print("analyzer done")
                    timer.invalidate()
                    analyzerWaitGroup.leave()
                }
            }
        }

        // Reader thread
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            defer {
                print("reader done")
                group.leave()
            }

            var packetCount = 0
            while keepReceiving {
                var readData = Data()
                do {
                   let (bytesRead, _) = try client.readDatagram(into: &readData)
                    self.readBufferLength += bytesRead
                    packetCount += 1
                } catch let error {
                    print("Error reading UDP packet \(error)")
                    continue
                }
            }
        }

        // Sender Thread
        let timeReplayStarted = Date.init()
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            defer {
                print("Sender done")
                group.leave()
            }

            for (index, packet) in self.replay.packets.enumerated() {
                let timePassed = timeReplayStarted.timeIntervalSinceNow * -1
                if self.settings.packetTiming {
                    if timePassed < packet.timestamp {
                        let sleepTime = UInt32((packet.timestamp - timePassed) * 1000000)
                        //print("sleeping for " + String(sleepTime) + " millionths of a second")
                        //sentOnTime += 1
                        usleep(sleepTime)
                    }
                }

                do {
                   try client.write(from: packet.payload, to: Socket.createAddress(for: spPair.ip, on: spPair.port)!)
                } catch let error {
                    print("Error sending UDP packet \(error)")
                    continue
                }

                if (testTimeout != 0) && (timePassed > testTimeout) {
                    break
                }

                let progress = Float(index + 1) / Float(self.replay.packets.count)
                Helper.runOnUIThread {
                    self.replayRunner.updateProgress(value: progress)
                    }
            }

            keepReceiving = false
            client.close()
        }

        group.wait()
        keepAnalyzing = false
        analyzerWaitGroup.wait()

        let timePassed = timeReplayStarted.timeIntervalSinceNow * -1

        var averageThroughputs: [Double: Double] = [:]

        for (timeSlice, bytesRead) in timeSlices {
            let mbitsRead = Double(bytesRead) / 125000
            averageThroughputs[timeSlice] = mbitsRead / timePerSlice
        }

        do {
            try sidechannel.sendDone(duration: timePassed)
            try sidechannel.sendTimeSlices(slices: averageThroughputs)
            try sidechannel.getResult()
        } catch let error {
            throw error
        }

        Helper.runOnUIThread {
            self.replayRunner.replayDone(type: self.replayType)
        }
    }

    private func runTCPReplay(portMapping: PortMapping, clientIP: String, numberOfTimeSlices: Double, testTimeout: Double) throws {
        defer {
            sidechannel.close()
        }

        // figure out the ip and port for the socket
        guard var spPair = portMapping.getPortMapping(ip: replay.destinationIP!, port: replay.port, prot: .tcp) else {
            throw ReplayError.sideChannelError(reason: LocalizedStrings.errors.portMappingError)
        }
        if spPair.ip == "" {
            spPair.ip = settings.serverIP
        }

        var client: Socket
        do {
            client = try Socket.create(family: family, type: .stream, proto: .tcp)
            try client.setReadTimeout(value: socketReadTimeout)
            try client.setWriteTimeout(value: socketWriteTimeout)
            try client.connect(to: spPair.ip, port: spPair.port, timeout: socketConnectTimeout)
        } catch let error {
            print("Error establishing TCP socket \(error)")
            throw ReplayError.connectionBlockError(reason: LocalizedStrings.errors.connectionBlockError)
        }

        defer {
            client.close()
        }

        let timeReplayStarted = Date.init()

        var keepAnalyzing = true
        var timeSlices: [Double: Int] = [:]
        let analyzerWaitGroup = DispatchGroup()
        let timePerSlice = Double(min(app.time, testTimeout)) / numberOfTimeSlices
        let semaphore = DispatchSemaphore(value: 1)
        analyzerWaitGroup.enter()

        Helper.runOnUIThread {
            var ran = 0
            _ = Timer.scheduledTimer(withTimeInterval: timePerSlice, repeats: true) { timer in
                ran += 1

                let timeSlice = Double(ran) * timePerSlice
                semaphore.wait()
                timeSlices[timeSlice] = self.readBufferLength
                self.readBufferLength = 0
                semaphore.signal()

                if !keepAnalyzing || self.forceQuit {
                    timer.invalidate()
                    analyzerWaitGroup.leave()
                }
            }
        }

        for (index, packet) in replay.packets.enumerated() {
            if forceQuit {
                return
            }
            let timePassed = timeReplayStarted.timeIntervalSinceNow * -1
            if (testTimeout != 0) && (timePassed > testTimeout) {
                break
            }

            do {
                _ = try handleTCPPacket(packet: packet, client: client, testTimeout: testTimeout, timeStarted: timeReplayStarted, sem: semaphore)
                let progress = Float(index + 1) / Float(replay.packets.count)
                Helper.runOnUIThread {
                    self.replayRunner.updateProgress(value: progress)
                }
            } catch let error {
                throw error
            }
        }

        print("Sent " + String(replay.packets.count) + " packets, " + String(fellBehind) + " fell behind, " + String(sentOnTime) + " were sent on time")

        Helper.runOnUIThread {
            self.replayRunner.updateProgress(value: 1.0)
        }

        let timePassed = timeReplayStarted.timeIntervalSinceNow * -1

        keepAnalyzing = false
        analyzerWaitGroup.wait()

        var averageThroughputs: [Double: Double] = [:]

        for (timeSlice, bytesRead) in timeSlices {
            let mbitsRead = Double(bytesRead) / 125000
            averageThroughputs[timeSlice] = mbitsRead / timePerSlice
        }

        do {
            try sidechannel.sendDone(duration: timePassed)
            try sidechannel.sendTimeSlices(slices: averageThroughputs)
            if app.isPortTest {
                var total: Double = 0
                for slice in averageThroughputs {
                    total += slice.value
                }
                app.appThroughput = total / Double(averageThroughputs.count)
            }
            try sidechannel.getResult()
        } catch let error {
            throw error
        }

        Helper.runOnUIThread {
            self.replayRunner.replayDone(type: self.replayType)
        }
    }

    private func handleTCPPacket(packet: Packet, client: Socket, testTimeout: Double, timeStarted: Date, sem: DispatchSemaphore) throws -> Int {
//        turn off timing for port tests
        if settings.packetTiming && app.name.contains("port") {
            let timePassed = timeStarted.timeIntervalSinceNow * -1
            if timePassed < packet.timestamp {
                let sleepTime = UInt32((packet.timestamp - timePassed) * 1000000)
                sentOnTime += 1
                usleep(sleepTime)
            } else {
                let interval = packet.timestamp - timePassed
                print("Falling behind " + String(interval))
                fellBehind += 1
            }
        }

        do {
            try client.write(from: packet.payload)
        } catch let error {
            print("error writing tcp payload \(error)")
            throw ReplayError.senderError(reason: LocalizedStrings.errors.tcpError)
        }

        let responseLength = packet.responseLength!

        if responseLength == 0 {
            return 0
        }

        var bufferLen = 0
        var reads = 0

        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: responseLength)
        buffer.initialize(repeating: 0, count: responseLength)

        defer {
            buffer.deinitialize(count: responseLength)
            buffer.deallocate()
        }

        while responseLength > bufferLen {
            let timePassed = timeStarted.timeIntervalSinceNow * -1
            if timePassed >= testTimeout {
                return bufferLen
            }
            reads += 1
            do {
                let bytesRead = try client.read(into: buffer, bufSize: responseLength, truncate: true)
                bufferLen += bytesRead
                sem.wait()
                self.readBufferLength += bytesRead
                sem.signal()
                if responseLength == bufferLen {
                    return bufferLen
                }
            } catch let error {
                print("Error reading TCP packet \(error)")
                throw ReplayError.receiveError
            }
        }

        return bufferLen
    }
}
