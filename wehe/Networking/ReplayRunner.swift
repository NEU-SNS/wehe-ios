//
//  ReplayRunner.swift
//  wehe
//
//  Created by Kirill Voloshin on 10/6/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
//  Handles running open/random replays for a single app

import Foundation
import Alamofire

class ReplayRunner {
    let replayView: ReplayViewProtocol
    let app: App
    let dpiTestID: Int
    var replay: Replay?
    var randomReplay: Replay?

    var replayer: Replayer?
    var resultWatcher: ResultWatcher?
    var forceQuit = false

    let settings: Settings

    init(replayView: ReplayViewProtocol, app: App, dpiTestID: Int = -1) {
        self.replayView = replayView
        self.app = app
        self.dpiTestID = dpiTestID
        self.settings = Globals.settings
    }

    func run(testRegion: TestRegion? = nil) {
        updateStatus(newStatus: .loadingFiles)
        DispatchQueue.global(qos: .utility).async {
            let success: Bool
            if let testRegion = testRegion {
                success = self.loadReplayJson(testRegion: testRegion)
            } else {
                success = self.loadReplayJson()
            }
            if success {
                if testRegion == nil {
                    self.app.historyCount = self.settings.historyCount
                    self.settings.historyCount += 1
                }
                Helper.runOnUIThread {
                    if testRegion != nil {
                        self.getDeviceIP(replayType: .dpi)
                    } else {
                        let randomNumber = Int.random(in: 0...1)
                        if randomNumber == 0 {
                            self.getDeviceIP(replayType: .original)
                        } else {
                            self.getDeviceIP(replayType: .random)
                        }
                    }
                }
            } else {
                Helper.runOnUIThread {
                    self.replayExitWithError(reason: LocalizedStrings.ReplayRunner.errorReadingReplay)
                }
            }
        }
    }

    func cancelReplay() {
        forceQuit = true
        if let replayer = replayer {
            replayer.cancel()
        }

        if let watcher = resultWatcher {
            watcher.cancel()
        }

    }

    func updateStatus(newStatus: ReplayStatus) {
        app.status = newStatus
        replayView.reloadUI()
    }

    func updateProgress(value: Float) {
        replayView.updateOverallProgress()
        var squishedValue = value / 2
        if app.replaysRan.count == 2 {
            squishedValue += 0.50
        }

        replayView.updateAppProgress(for: app, value: squishedValue * 100)
    }

    func resetProgress() {
        replayView.updateOverallProgress()
        var squishedValue = Float(0)
        if app.replaysRan.count == 2 {
            squishedValue += 0.50
        }
        replayView.updateAppProgress(for: app, value: squishedValue * 100)
    }

    // called when an error occurs when running the replay on a separate thread
    func replayFailed(error: ReplayError) {
        switch error {
        case .receiveError:replayExitWithError(reason: LocalizedStrings.ReplayRunner.errorReceivingPackets)
        case .senderError(let reason): replayExitWithError(reason: reason)
        case .sideChannelError(let reason): replayExitWithError(reason: reason)
        case .otherError(let reason): replayExitWithError(reason: reason)
        }
    }

    func replayDone(type: ReplayType) {
        if forceQuit {
            return
        }

        switch type {
        case .original:
            if !app.replaysRan.contains(.random) {
                getDeviceIP(replayType: .random)
            } else {
                updateStatus(newStatus: .finishedReplay)
                app.timesRan += 1
                DispatchQueue.global(qos: .utility).async {
                    let resultServerPort = Settings.https ? self.settings.httpsResultsPort : self.settings.resultsPort
                    let id = self.settings.randomID
                    let historyCount = self.app.historyCount ?? 0
                    let app = self.app
                    let replayView = self.replayView
                    let settings = self.settings
                    let resultWatcher = ResultWatcher(resultServer: settings.serverIP, resultServerPort: resultServerPort, id: id, historyCount: historyCount, app: app, replayView: replayView)
                    self.resultWatcher = resultWatcher
                    resultWatcher.requestAnalysis(testID: 1)
                }
                replayView.replayFinished()
            }
        case .random:
            if !app.replaysRan.contains(.original) {
                getDeviceIP(replayType: .original)
            } else {
                updateStatus(newStatus: .finishedReplay)
                app.timesRan += 1
                DispatchQueue.global(qos: .utility).async {
                    let resultServerPort = Settings.https ? self.settings.httpsResultsPort : self.settings.resultsPort
                    let id = self.settings.randomID
                    let historyCount = self.app.historyCount ?? 0
                    let app = self.app
                    let replayView = self.replayView
                    let settings = self.settings
                    let resultWatcher = ResultWatcher(resultServer: settings.serverIP, resultServerPort: resultServerPort, id: id, historyCount: historyCount, app: app, replayView: replayView)
                    self.resultWatcher = resultWatcher
                    resultWatcher.requestAnalysis(testID: 1)
                }
                replayView.replayFinished()
            }
        case .dpi:
            let resultServerPort = Settings.https ? self.settings.httpsResultsPort : self.settings.resultsPort
            let id = self.settings.randomID
            let historyCount = self.app.historyCount ?? 0
            let app = self.app
            let replayView = self.replayView
            let settings = self.settings
            let resultWatcher = ResultWatcher(resultServer: settings.serverIP, resultServerPort: resultServerPort, id: id, historyCount: historyCount, app: app, replayView: replayView)
            self.resultWatcher = resultWatcher
            resultWatcher.requestAnalysis(testID: self.dpiTestID)
        }
    }

    // MARK: Private methods
    private func replayExitWithError(reason: String) {
        app.status = .error
        app.errorString = reason
        resetProgress()
        replayView.reloadUI()
        replayView.replayFinished()
    }

    private func loadReplayJson(testRegion: TestRegion? = nil) -> Bool {
        let appInfo = app
        let replayFile = appInfo.replayFile
        let randomReplayFile = appInfo.randomReplayFile

        let group = DispatchGroup()
        var error = false

        group.enter()
        DispatchQueue.global(qos: .utility).async {
            defer {
                group.leave()
            }

            if let replayJSON = Helper.readJSONFile(filename: replayFile) {
                if let replay = Replay(blob: replayJSON, testRegion: testRegion) {
                    self.replay = replay
                    return
                }
            }

            error = true
            return
        }

        group.enter()
        DispatchQueue.global(qos: .utility).async {
            defer {
                group.leave()
            }

            if let randomReplayJSON = Helper.readJSONFile(filename: randomReplayFile) {
                if let randomReplay = Replay(blob: randomReplayJSON) {
                    self.randomReplay = randomReplay
                    return
                }
            }

            error = true
            return

        }

        group.wait()
        return !error
    }

    private func getDeviceIP(replayType: ReplayType) {
        if forceQuit {
            return
        }

        replayView.ranTests(number: 1)
        app.replaysRan.append(replayType)

        var currentReplay: Replay
        switch replayType {
        case .original:
            currentReplay = replay!
        case .random:
            currentReplay = randomReplay!
        case .dpi:
            currentReplay = replay!
        }

        switch currentReplay.type {
        case .udp:
            startReplay(deviceIP: "127.0.0.1", type: replayType, replay: currentReplay)
        case .tcp:
            let url = Helper.makeURL(ip: settings.serverIP, port: String(currentReplay.port), api: "WHATSMYIPMAN")
            Alamofire.request(url).responseString { response in
                if let result = response.result.value {
                    self.startReplay(deviceIP: result, type: replayType, replay: currentReplay)
                } else {
                    self.startReplay(deviceIP: "127.0.0.1", type: replayType, replay: currentReplay)
                }
            }
        }
    }

    private func startReplay(deviceIP: String, type: ReplayType, replay: Replay) {
        if forceQuit {
            return
        }

        do {
            let replayer = try Replayer(settings: settings, deviceIP: deviceIP, replay: replay, replayType: type, replayRunner: self, app: app, serverIP: settings.serverIP)
            self.replayer = replayer
            DispatchQueue.global(qos: .utility).async {
                sleep(1)
                replayer.runReplay(dpiTestID: self.dpiTestID)
            }

        } catch let error as ReplayError {
            switch error {
            case .senderError(let reason): replayExitWithError(reason: reason)
            case .sideChannelError(let reason): replayExitWithError(reason: reason)
            case .receiveError: replayExitWithError(reason: LocalizedStrings.ReplayRunner.receiverError)
            case .otherError(let reason): replayExitWithError(reason: reason)
            }
        } catch let error {
            print(error)
            replayExitWithError(reason: LocalizedStrings.ReplayRunner.errorUnknownError)
        }

    }
}

enum ReplayType {
    case original
    case random
    case dpi
}
