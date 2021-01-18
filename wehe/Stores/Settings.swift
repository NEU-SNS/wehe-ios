//
//  Settings.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/11/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import Starscream

class Settings {

    // MARK: Properties
    var consent: Bool {
        didSet {
            defaults.set(consent, forKey: DefaultKeys.consent)
        }
    }

    var randomID: String {
        didSet {
            defaults.set(randomID, forKey: DefaultKeys.randomID)
        }
    }

    var extraString: String {
        didSet {
            defaults.set(extraString, forKey: DefaultKeys.extraString)
        }
    }

    var server: String {
        didSet {
            defaults.set(server, forKey: DefaultKeys.server)
        }
    }

    var serverIP: String {
        didSet {
            defaults.set(serverIP, forKey: DefaultKeys.serverIP)
        }
    }
    
    var ipVersion: String {
        didSet {
            defaults.set(ipVersion, forKey: DefaultKeys.ipVersion)
        }
    }

    var port: Int {
        didSet {
            defaults.set(port, forKey: DefaultKeys.port)
        }
    }

    var resultsPort: Int {
        didSet {
            defaults.set(resultsPort, forKey: DefaultKeys.resultsPort)
        }
    }

    var httpsPort: Int {
        didSet {
            defaults.set(httpsPort, forKey: DefaultKeys.httpsPort)
        }
    }

    var httpsResultsPort: Int {
        didSet {
            defaults.set(httpsResultsPort, forKey: DefaultKeys.httpsResultsPort)
        }
    }

    var confirmationReplays: Bool {
        didSet {
            defaults.set(confirmationReplays, forKey: DefaultKeys.confirmationReplays)
        }
    }
    
    var connectedWebsockets: Dictionary<String, Bool> {
        didSet {
            defaults.set(connectedWebsockets, forKey: DefaultKeys.connectedWebsockets)
        }
    }
    
    var sendStats: Bool {
        didSet {
            defaults.set(sendStats, forKey: DefaultKeys.sendStats)
        }
    }

    var areaThreshold: Double {
        didSet {
            defaults.set(areaThreshold, forKey: DefaultKeys.areaThreshold)
        }
    }

    var pValueThreshold: Double {
        didSet {
            defaults.set(pValueThreshold, forKey: DefaultKeys.pValueThreshold)
        }
    }

    var defaultThresholds: Bool {
        didSet {
            defaults.set(defaultThresholds, forKey: DefaultKeys.defaultThresholds)
        }
    }

    var defaultAreaThreshold = DefaultSettings.areaThreshold
    var defaultpValueThreshold = DefaultSettings.pValueThreshold
    var defaultKS2Ratio = DefaultSettings.ks2Ratio

    var latitude: String?
    var longitude: String?

    var historyCount: Int {
        didSet {
            defaults.set(historyCount, forKey: DefaultKeys.historyCount)
        }
    }

    var portTestID: Int {
        didSet {
            defaults.set(portTestID, forKey: DefaultKeys.portTestID)
        }
    }

    var packetTiming: Bool {
        didSet {
            defaults.set(packetTiming, forKey: DefaultKeys.packetTiming)
        }
    }

    var firstTimeLaunch: Bool {
        didSet {
            defaults.set(firstTimeLaunch, forKey: DefaultKeys.firstTimeLaunch)
        }
    }

    var askedToRate: Bool {
        didSet {
            defaults.set(askedToRate, forKey: DefaultKeys.askedToRate)
        }
    }

    let defaults = UserDefaults.standard

    // Misc constants
    static let appFileName = "app_list"
    static let appID = "1309242023"
    static let placeholderImageName = "placeholder"
    static let https = true
    static let noDifferentiationColor = UIColor(red: 0, green: 0.8078, blue: 0.2275, alpha: 1.0)
    static let pfxPassword = "weheiOSs1hTqETC8D"
    static let metaDataserver = "wehe-metadata.meddle.mobi"
    let fallback_server = "wehe2.meddle.mobi"

    // Key constants to use for settings storage
    struct DefaultKeys {
        static let consent = "userConsentedNew"
        static let randomID = "randomID"
        static let extraString = "extraString"
        static let server = "server"
        static let serverIP = "serverIP"
        static let ipVersion = "IPv4"
        static let port = "port"
        static let connectedWebsockets = "connectedWebsockets"
        static let resultsPort = "resultsPort"
        static let httpsPort = "httpsPort"
        static let httpsResultsPort = "httpsResultsPort"
        static let confirmationReplays = "confirmationReplays"
        static let areaThreshold = "areaTestThreshold"
        static let pValueThreshold = "KS2PValueThreshold"
        static let defaultThresholds = "defaultSettings"
        static let historyCount = "historyCount"
        static let portTestID = "portTestID"
        static let sendStats = "sendStats"
        static let packetTiming = "packetTiming"
        static let firstTimeLaunch = "firstTimeLaunch"
        static let askedToRate = "askedToRate"
    }

    struct DefaultSettings {
        static let consent = false
        static let extraString = "DiffDetector"
        static let server = "wehe4.meddle.mobi"
        static let servers = ["wehe4.meddle.mobi"]
        static let port = 55555
        static let resultsPort = 56565
        static let httpsPort = 55556
        static let httpsResultsPort = 56566
        static let confirmationReplays = true
        static let areaThreshold = 0.5
        static let pValueThreshold = 0.01
        static let defaultThresholds = true
        static let ks2Ratio = 0.95
        static let historyCount = 0
        static let portTestID = 0
        static let sendStats = true
        static let packetTiming = true
        static let firstTimeLaunch = true
        static let askedToRate = false
        static let connectedWebsockets = [String: Bool]()
    }

    init() {

        if defaults.object(forKey: DefaultKeys.consent) != nil {
            consent = defaults.bool(forKey: DefaultKeys.consent)
        } else {
            consent = DefaultSettings.consent
        }

        if let randomID = defaults.string(forKey: DefaultKeys.randomID) {
            self.randomID = randomID
        } else {
            let length = 10
            let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let len = UInt32(letters.length)

            var randomString = ""

            for _ in 0 ..< length {
                let rand = arc4random_uniform(len)
                var nextChar = letters.character(at: Int(rand))
                randomString += NSString(characters: &nextChar, length: 1) as String
            }
            self.randomID = randomString
            defaults.set(randomID, forKey: DefaultKeys.randomID)
        }

        extraString = defaults.string(forKey: DefaultKeys.extraString) ?? DefaultSettings.extraString
        
        if defaults.object(forKey: DefaultKeys.confirmationReplays) != nil {
            confirmationReplays = defaults.bool(forKey: DefaultKeys.confirmationReplays)
        } else {
            confirmationReplays = DefaultSettings.confirmationReplays
        }

        if defaults.object(forKey: DefaultKeys.areaThreshold) != nil {
            areaThreshold = defaults.double(forKey: DefaultKeys.areaThreshold)
        } else {
            areaThreshold = DefaultSettings.areaThreshold
        }

        if defaults.object(forKey: DefaultKeys.pValueThreshold) != nil {
            pValueThreshold = defaults.double(forKey: DefaultKeys.pValueThreshold)
        } else {
            pValueThreshold = DefaultSettings.pValueThreshold
        }

        if defaults.object(forKey: DefaultKeys.port) != nil {
            port = defaults.integer(forKey: DefaultKeys.port)
        } else {
            port = DefaultSettings.port
        }

        if defaults.object(forKey: DefaultKeys.resultsPort) != nil {
            resultsPort = defaults.integer(forKey: DefaultKeys.resultsPort)
        } else {
            resultsPort = DefaultSettings.resultsPort
        }

        if defaults.object(forKey: DefaultKeys.httpsPort) != nil {
            httpsPort = defaults.integer(forKey: DefaultKeys.httpsPort)
        } else {
            httpsPort = DefaultSettings.httpsPort
        }

        if defaults.object(forKey: DefaultKeys.httpsResultsPort) != nil {
            httpsResultsPort = defaults.integer(forKey: DefaultKeys.httpsResultsPort)
        } else {
            httpsResultsPort = DefaultSettings.httpsResultsPort
        }

        if defaults.object(forKey: DefaultKeys.defaultThresholds) != nil {
            defaultThresholds = defaults.bool(forKey: DefaultKeys.defaultThresholds)
        } else {
            defaultThresholds = DefaultSettings.defaultThresholds
        }

        if defaults.object(forKey: DefaultKeys.historyCount) != nil {
            historyCount = defaults.integer(forKey: DefaultKeys.historyCount)
        } else {
            historyCount = DefaultSettings.historyCount
        }

        if defaults.object(forKey: DefaultKeys.portTestID) != nil {
            portTestID = defaults.integer(forKey: DefaultKeys.portTestID)
        } else {
            portTestID = DefaultSettings.portTestID
        }

        if defaults.object(forKey: DefaultKeys.sendStats) != nil {
            sendStats = defaults.bool(forKey: DefaultKeys.sendStats)
        } else {
            sendStats = DefaultSettings.sendStats
        }

        if defaults.object(forKey: DefaultKeys.packetTiming) != nil {
            packetTiming = defaults.bool(forKey: DefaultKeys.packetTiming)
        } else {
            packetTiming = DefaultSettings.packetTiming
        }

        if defaults.object(forKey: DefaultKeys.firstTimeLaunch) != nil {
            firstTimeLaunch = defaults.bool(forKey: DefaultKeys.firstTimeLaunch)
        } else {
            firstTimeLaunch = DefaultSettings.firstTimeLaunch
        }

        if defaults.object(forKey: DefaultKeys.askedToRate) != nil {
            askedToRate = defaults.bool(forKey: DefaultKeys.askedToRate)
        } else {
            askedToRate = DefaultSettings.askedToRate
        }

        server = defaults.string(forKey: DefaultKeys.server) ?? DefaultSettings.server
        serverIP = Helper.dnsLookup(hostname: server) ?? DefaultSettings.server

        if serverIP.contains(":") {
            ipVersion = "IPv6"
        } else {
            ipVersion = "IPv4"
        }
        connectedWebsockets = [String: Bool]()
        
    }
}
