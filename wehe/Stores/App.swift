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

class App: NSObject, NSCopying {

    // MARK: Properties
    var name: String
    var size: String?
    var time: Double
    var icon: String
    var replayFile: String
    var randomReplayFile: String
    var isSelected: Bool = true

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

    init?(name: String, size: String?, time: Double, icon: String?, replayFile: String, randomReplayFile: String) {

        guard !name.isEmpty && !replayFile.isEmpty && !randomReplayFile.isEmpty else {
            return nil
        }

        self.name = name
        self.size = size
        self.time = time
        self.icon = icon ?? "placeholder"
        self.replayFile = replayFile
        self.randomReplayFile = randomReplayFile
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

    // MARK: NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = App(name: name, size: size, time: time, icon: icon, replayFile: replayFile, randomReplayFile: randomReplayFile)

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

    var description: String {
        switch self {
        case .queued:               return LocalizedStrings.App.queued
        case .loadingFiles:         return LocalizedStrings.App.loadingFiles
        case .askingForPermission:  return LocalizedStrings.App.askingForPermission
        case .receivedPermission:   return LocalizedStrings.App.receivedPermission
        case .receivingPortMapping: return LocalizedStrings.App.receivingPortMapping
        case .originalReplay:       return LocalizedStrings.App.originalReplay
        case .randomReplay:         return LocalizedStrings.App.randomReplay
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
