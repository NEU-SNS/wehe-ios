//
//  App.swift
//  wehe
//
//  Created by Kirill Voloshin on 9/12/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
//  Contains information about the app and its resources

import Foundation
import UIKit
import Starscream
import Alamofire
import SwiftyJSON

class App: NSObject, NSCopying, WebSocketDelegate {

    // MARK: Properties
    var name: String
    var size: String?
    var time: Double
    var icon: String
    var replayFile: String
    var randomReplayFile: String
    var isSelected: Bool = true
    var isPortTest: Bool
    var isLargeTest: Bool
    var appType: String?
    var baselinePort: String = "443"
    var baselinePortTest: Bool = true
    var portTestID: Int = 0
    var prioritized: Bool = false

    var timesRan = 0
    var appThroughput: Double?
    var nonAppThroughput: Double?
    var status = ReplayStatus.queued
    var date: Date?
    var errorString: String = ""
    var historyCount: Int?
    var userID: String?
    var testID: String?
    var differentiation: DifferentiationStatus?
    var result: Result?
    var replaysRan = [ReplayType]()
    var progress: CGFloat = 0
    var settings: Settings
    
    var wss_socket = WebSocket(request: URLRequest(url: URL(string: "http://localhost:8080")!))
    var wss_serverIP: String = "10.0.0.0"
    var mlab_envelope_url = "mlab_envelope_url"
    var wehe_server_domain = "mlab_default"
    var wss_socket_is_connected = false

    init?(name: String, size: String?, time: Double, icon: String?, replayFile: String, randomReplayFile: String, isPortTest: Bool = false, isLargeTest: Bool = false, appType: String?) {

        guard !name.isEmpty && !replayFile.isEmpty && !randomReplayFile.isEmpty else {
            return nil
        }

        self.name = name
        self.size = size
        self.time = time
        self.icon = icon ?? "placeholder"
        self.replayFile = replayFile
        self.randomReplayFile = randomReplayFile
        self.isPortTest = isPortTest
        self.isLargeTest = isLargeTest
        self.appType = appType
        if self.name.contains("Port 443") {
            self.baselinePortTest = true
        } else {
            self.baselinePortTest = false
        }
        self.settings = Globals.settings
    }

    func reset() {
        status = .queued
        errorString = ""
        appThroughput = nil
        nonAppThroughput = nil
        historyCount = nil
        userID = nil
        testID = nil
        timesRan = 0
        date = nil
        differentiation = nil
        result = nil
        replaysRan = [ReplayType]()
        progress = 0
    }
    
    // the websocket handler
    func didReceive(event: WebSocketEvent, client: WebSocket) {
      switch event {
      case .connected(let headers):
        self.wss_socket_is_connected = true
      case .disconnected(let reason, let closeCode):
        self.wss_socket_is_connected = false
        let keyExists = self.settings.connectedWebsockets[self.wehe_server_domain] != nil
        if keyExists {
            self.settings.connectedWebsockets.removeValue(forKey: self.wehe_server_domain)
        }
      case .text(let text):
        print("wss received text: \(text)")
      case .binary(let data):
        print("wss received data: \(data)")
      case .pong(let pongData):
        print("wss received pong: \(String(describing: pongData))")
      case .ping(let pingData):
        print("wss received ping: \(String(describing: pingData))")
      case .error(let error):
        print("wss websocket error when trying to connect to ", self.wehe_server_domain, error)
      case .viabilityChanged:
        print("wss viabilityChanged")
      case .reconnectSuggested:
        print("wss reconnectSuggested")
      case .cancelled:
        self.wss_socket_is_connected = false
        let keyExists = self.settings.connectedWebsockets[self.wehe_server_domain] != nil
        if keyExists {
            self.settings.connectedWebsockets.removeValue(forKey: self.wehe_server_domain)
        }
        print("wss cancelled in did receive", self.wehe_server_domain)
      }
    }
    
    func mlab_server_lookup() {
        self.wss_socket_is_connected = false
        let server_locate_api_url =
        "https://locate.measurementlab.net/v2/nearest/wehe/replay"
//        mlab sandbox api url
//        let server_locate_api_url =
//            "https://locate-dot-mlab-sandbox.appspot.com/v2/nearest/wehe/replay"
        AF.request(server_locate_api_url).responseJSON { response in
        switch response.result {
        case .success(let value):
            let json_response = JSON(value)
            let results: [JSON] = json_response["results"].arrayValue
            for mlab_result in results {
                let wehe_mlab_result = "wehe-" + mlab_result["machine"].stringValue
                let keyExists = self.settings.connectedWebsockets[wehe_mlab_result] != nil
                if !keyExists {
                    let result = mlab_result
                    let urls = JSON(result["urls"])
                    for (_, mlab_envelope_url_t) in urls {
                        self.mlab_envelope_url = mlab_envelope_url_t.description
                    }
                    self.wehe_server_domain = "wehe-" + result["machine"].stringValue
                    self.wss_serverIP = Helper.dnsLookup(hostname: self.wehe_server_domain) ?? self.wehe_server_domain
                    var wss_request = URLRequest(url: URL(string: self.mlab_envelope_url)!)
                    wss_request.timeoutInterval = 2 // timeout after 2 seconds
                    self.wss_socket = WebSocket(request: wss_request)
                    self.wss_socket.connect()
                    self.wss_socket.delegate = self
                    sleep(2)
                    // check whether connected
                    if self.wss_socket_is_connected {
                        self.settings.serverIP = self.wss_serverIP
                        self.settings.connectedWebsockets[self.wehe_server_domain] = true
                        break
                    }
                }
            }
            
        case .failure(let error):
            print(error)
            }
        }
    }

    // MARK: NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = App(name: name, size: size, time: time, icon: icon, replayFile: replayFile, randomReplayFile: randomReplayFile, isPortTest: isPortTest, appType: appType)

        return copy as Any
    }

    // MARK: Public methods
    func getStatusString() -> String {
        switch status {
        case .error: return errorString
        default:     return status.description
        }
    }

}

enum ReplayStatus: CustomStringConvertible {
    case queued
    case loadingFiles
    case askingForPermission
    case receivedPermission
    case receivingPortMapping
    case originalReplay
    case randomReplay
    case finishedReplay
    case waitingForResults
    case receivedResults
    case willRerun
    case error
    case testPortReplay
    case baselinePortReplay

    var description: String {
        switch self {
        case .queued:               return LocalizedStrings.App.queued
        case .loadingFiles:         return LocalizedStrings.App.loadingFiles
        case .askingForPermission:  return LocalizedStrings.App.askingForPermission
        case .receivedPermission:   return LocalizedStrings.App.receivedPermission
        case .receivingPortMapping: return LocalizedStrings.App.receivingPortMapping
        case .originalReplay:       return LocalizedStrings.App.originalReplay
        case .randomReplay:         return LocalizedStrings.App.randomReplay
        case .testPortReplay:       return LocalizedStrings.App.testPortReplay
        case .baselinePortReplay:   return LocalizedStrings.App.baselinePortReplay
        case .finishedReplay:       return LocalizedStrings.App.finishedReplay
        case .waitingForResults:    return LocalizedStrings.App.waitingForResults
        case .receivedResults:      return LocalizedStrings.App.receivedResults
        case .willRerun:            return LocalizedStrings.App.willRerun
        case .error:                return LocalizedStrings.App.error
        }
    }
}

enum DifferentiationStatus: CustomStringConvertible {
    case noDifferentiation
    case inconclusive
    case differentiation

    var description: String {
        switch self {
        case .differentiation:      return LocalizedStrings.App.differentiation
        case .noDifferentiation:    return LocalizedStrings.App.noDifferentiation
        case .inconclusive:         return LocalizedStrings.App.inconclusive
        }
    }
}
