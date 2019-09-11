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
    var manager: SessionManager?

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
        manager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default, delegate: SessionManager.default.delegate, serverTrustPolicyManager: Helper.serverTrustPoliceManager(server: annalysisIP))

        manager!.request(analysisUrl, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString)).responseJSON(queue: queue) { response in
            switch response.result {
            case .success:
                if let result = response.result.value {
                    let json = JSON(result)
                    if json != JSON.null && json["success"].boolValue {
                        self.updateStatus(status: .waitingForResults)
                        sleep(2)
                        self.getResults(testID: testID)
                        return
                    }
                }
                fallthrough
            case .failure:
                if self.analysisAttempts <= self.maxAnalysisAttempts {
                    self.updateStatus(status: .error, error: "Error requesting analysis from the server, retrying")
                    self.requestAnalysis(testID: testID)
                } else {
                    self.updateStatus(status: .error, error: "Error requesting analysis from the server. Please rerun the test later")
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

        manager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default, delegate: SessionManager.default.delegate, serverTrustPolicyManager: Helper.serverTrustPoliceManager(server: annalysisIP))
        manager!.session.configuration.timeoutIntervalForRequest = 5
        manager!.request(analysisUrl, parameters: parameters).responseJSON(queue: queue) { response in
            switch response.result {
            case .success:
            if let result = response.result.value {
                let json = JSON(result)
                if json != JSON.null && json["success"].boolValue {
                    print(response.request!.description)
                    Helper.runOnUIThread {
                        self.gotResult = true
                        self.updateStatus(status: .receivedResults)

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
        guard let result = Result(blob: json, appName: appName, server: settings.server, area: settings.areaThreshold, ks2p: settings.pValueThreshold) else {
            self.updateStatus(status: .error, error: "Received malformed results from the server")
            return nil
        }

        let areaTestThreshold =  settings.defaultThresholds ?  settings.defaultAreaThreshold : settings.areaThreshold
        let ks2Threshold = settings.defaultThresholds ? settings.defaultpValueThreshold : settings.pValueThreshold
        let ks2Ratio = settings.defaultKS2Ratio

        let aboveArea = result.areaTest >= areaTestThreshold
        let belowP = result.ks2pVal < ks2Threshold
        let trustPValue = result.ks2RatioTest >= ks2Ratio

//        print("areaTestThreshold " + String(areaTestThreshold * 100))
//        print("ks2Threshold " + String(ks2Threshold * 100))
//        print("ks2Ratio " + String(ks2Ratio * 100))
//
//        print("---")
//
//        print("areaTest " + String(result.areaTest * 100))
//        print("ks2pVal " + String(result.ks2pVal * 100))
//        print("ks2RatioTest " + String(result.ks2RatioTest * 100))
//
//        print("---")
//
//        print("aboveArea " + String(aboveArea))
//        print("belowP " + String(belowP))
//        print("trustPValue " + String(trustPValue))

        var differentiation = false
        var inconclusive = false

        differentiation = trustPValue && belowP && aboveArea
        inconclusive = !trustPValue && belowP && aboveArea

//        if !trustPValue {
//            differentiation = aboveArea
//        } else {
//            if aboveArea && belowP {
//                differentiation = true
//            }
//
//            if aboveArea != belowP {
//                inconclusive = true
//            }
//        }

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
//        app.differentiation = result.differentiation
//        app.appThroughput = result.originalAverageThroughput
//        app.nonAppThroughput = result.testAverageThroughput
//        replayViewController.receivedResult(result: result, app: app)

    }
}
