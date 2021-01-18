//
//  ResultWatcher.swift
//  wehe
//
//  Created by Kirill Voloshin on 10/30/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
//  Responsible for requesting and parsing results

import Foundation
import Alamofire
import SwiftyJSON

class ResultWatcher {
    // MARK: Properties
    let analysisUrl: String
    let annalysisIP: String
    let id: String
    let historyCount: Int
    let app: App
    let appName: String
    let replayView: ReplayViewProtocol
    let settings: Settings

    let sleepConstant = 1
    let sleepBeforeAnalysisRequest = 3
    let maxAnalysisAttempts = 5
    let maxResultAttempts = 20

    var gotResult = false
    var analysisAttempts = 0
    var resultAttempts = 0

    var forceQuit = false
    var session: Session!

    init(resultServer: String, resultServerPort: Int, id: String, historyCount: Int, app: App, replayView: ReplayViewProtocol) {
        self.id = id
        self.historyCount = historyCount
        self.app = app
        self.appName = app.name
        self.replayView = replayView
        self.settings = Globals.settings
        self.annalysisIP = resultServer
        analysisUrl = Helper.makeURL(ip: resultServer, port: String(resultServerPort), api: "Results", https: true)
    }

    // MARK: Methods
    func cancel() {
        forceQuit = true
    }

    func requestAnalysis(testID: Int) {
        if forceQuit {
            return
        }

        let parameters = ["command": "analyze", "userID": id, "historyCount": String(historyCount), "testID": String(testID)]
        analysisAttempts += 1
        sleep(UInt32(sleepBeforeAnalysisRequest * analysisAttempts))

        // Alamofire runs the callback on the main thread by default for some reason
        let queue = DispatchQueue.global(qos: .utility)
        session = Session(configuration: URLSessionConfiguration.af.default, serverTrustManager: Helper.getServerTrustManager(server: annalysisIP))
        session.request(analysisUrl, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString)).responseJSON(queue: queue) { response in
            switch response.result {
            case .success(let value):
                    let json = JSON(value)
                    if json != JSON.null && json["success"].boolValue {
                        self.updateStatus(status: .waitingForResults)
                        sleep(2)
                        self.getResults(testID: testID)
                        return
                    }
                fallthrough
            case .failure:
                if self.analysisAttempts <= self.maxAnalysisAttempts {
                    self.updateStatus(status: .error, error: "Error requesting analysis from the server, retrying")
                    self.requestAnalysis(testID: testID)
                } else {
                    self.updateStatus(status: .error, error: "Error sending or receiving result message")
                }

            }
        }
    }

    // MARK: Private Methods
    private func getResults(testID: Int) {
        if forceQuit {
            return
        }

        guard !gotResult else {
            return
        }

        guard resultAttempts <= maxResultAttempts else {
            self.updateStatus(status: .error, error: "Error getting results from the server. Please rerun the test later")
            return
        }

        let parameters = ["command": "singleResult", "userID": id, "historyCount": String(historyCount), "testID": String(testID)]
        let queue = DispatchQueue.global(qos: .utility)

        session = Session(configuration: URLSessionConfiguration.af.default, serverTrustManager: Helper.getServerTrustManager(server: annalysisIP))
        session.sessionConfiguration.timeoutIntervalForRequest = 5
        session.request(analysisUrl, parameters: parameters).responseJSON(queue: queue) { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if json != JSON.null && json["success"].boolValue {
                    Helper.runOnUIThread {
                        self.gotResult = true
                        self.updateStatus(status: .receivedResults)
                        if self.app.wss_socket_is_connected { // connected to a mlab server, need to disconnect
                            print("wss result received, ", self.app.name, self.app.wehe_server_domain)
                            self.app.wss_socket.disconnect()
                        }

                        if let serverResult = self.handleResult(json: json, appName: self.appName) {
                            self.app.differentiation = serverResult.differentiation
                            self.app.appThroughput = serverResult.originalAverageThroughput
                            self.app.nonAppThroughput = serverResult.testAverageThroughput
                            self.app.userID = serverResult.userID
                            self.app.testID = serverResult.testID
                            self.replayView.receivedResult(app: self.app, result: serverResult)
                        }
                    }
                } else {
                   fallthrough
                }
            case .failure:
                self.resultAttempts += 1
                sleep(UInt32(self.sleepConstant * self.resultAttempts))
                self.getResults(testID: testID)
            }
        }
    }

    private func updateStatus(status: ReplayStatus, error: String = "") {
        Helper.runOnUIThread {
            self.app.status = status
            self.app.errorString = error
            self.replayView.reloadUI()
        }
    }

    private func handleResult(json: JSON, appName: String) -> Result? {
        // Getting carrier info for this test
        var carrier = LocalizedStrings.Generic.defaultCarrier
        if !Helper.isOnWiFi() {
            carrier = Helper.getCarrier() ?? "unknown"
        }
        guard let result = Result(blob: json, appName: appName, server: settings.server, carrier: carrier, ipVersion: settings.ipVersion, area: settings.areaThreshold, ks2p: settings.pValueThreshold) else {
            self.updateStatus(status: .error, error: "Received malformed results from the server")
            return nil
        }

        var areaTestThreshold =  settings.defaultThresholds ?  settings.defaultAreaThreshold : settings.areaThreshold
        let ks2Threshold = settings.defaultThresholds ? settings.defaultpValueThreshold : settings.pValueThreshold
        let ks2Ratio = settings.defaultKS2Ratio
        
        // If the area test threshold is default value AND
        // one of the throughput is >= 10 Mbps, we should adjust the threshold
        if areaTestThreshold == 0.5 && max(result.testAverageThroughput,
                                            result.originalAverageThroughput) >= 10 {
            areaTestThreshold = 0.3
        }

        let aboveArea = abs(result.areaTest) >= areaTestThreshold
        let belowP = result.ks2pVal < ks2Threshold
        let trustPValue = result.ks2RatioTest >= ks2Ratio

        var differentiation = false
        var inconclusive = false

        if aboveArea {
            if trustPValue && aboveArea && belowP {
                differentiation = true
            } else {
                inconclusive = true
            }
        }

        if inconclusive {
            result.differentiation = .inconclusive
        } else if differentiation {
            result.differentiation = .differentiation
        } else {
            result.differentiation = .noDifferentiation
        }

        var diffDebugString: String
        switch result.differentiation! {
        case .differentiation: diffDebugString = "differentiation"
        case .noDifferentiation: diffDebugString = "no differentiation"
        case .inconclusive: diffDebugString = "inconclusive"
        }

        print("[RESULTS] " + result.replayName + ";" + String(result.areaTest) + ";" + String(result.ks2pVal) + ";" + String(result.ks2RatioTest) + ";" + String(result.historyCount)
            + ";" + diffDebugString + ";" + String(round(result.originalAverageThroughput * 1000) / 1000) + ";" + String(round(result.testAverageThroughput * 1000) / 1000))

        return result

    }
}
