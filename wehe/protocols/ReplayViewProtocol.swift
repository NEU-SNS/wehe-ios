//
//  ReplayViewControllerInterface.swift
//  wehe
//
//  Created by Ivan Chen on 4/16/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import Foundation

protocol ReplayViewProtocol {
    func reloadUI()
    func updateOverallProgress()
    func updateAppProgress(for: App, value: Float)
    func replayFinished()
    func receivedResult(app: App, result: Result)
    func ranTests(number: Int)
}

enum ReplayError: Error {
    case sideChannelError(reason: String)
    case senderError(reason: String)
    case connectionBlockError(reason: String)
    case receiveError
    case otherError(reason: String)
}
