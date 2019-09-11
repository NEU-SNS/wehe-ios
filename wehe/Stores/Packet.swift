//
//  Packet.swift
//  wehe
//
//  Created by Kirill Voloshin on 10/10/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
// Stores infromation for a single packet in a json replay

import Foundation
import SwiftyJSON
import os.log

class Packet {
    let cSPair: String
    let timestamp: Double
    let payload: Data

    // for TCP only
    let responseLength: Int?
    let responseHash: String?

    // for UDP
    let end: Bool?

    struct Keys {
        static let cSPair = "c_s_pair"
        static let timestamp = "timestamp"
        static let payload = "payload"
        static let responseLength = "response_len"
        static let responseHash = "response_hash"
        static let end = "end"
    }

    init?(blob: JSON, bound: (left: Int, right: Int)? = nil) {
        if let cSPair = blob[Keys.cSPair].string {
            self.cSPair = cSPair
        } else {
            os_log("Error parsing packet c_s_pair", type: .error)
            return nil
        }

        if let timestamp = blob[Keys.timestamp].double {
            self.timestamp = timestamp
        } else {
            os_log("Error parsing packet timestamp", type: .error)
            return nil
        }

        if var payload = blob[Keys.payload].string {
            if let bound = bound {
                payload = Helper.flipHex(payload, left: bound.left, right: bound.right)
            }

            if let parsedPayload = Helper.hexStringToData(from: payload) {
                self.payload = parsedPayload
            } else {
                os_log("Error converting packet payload to data", type: .error)
                return nil
            }
        } else {
            os_log("Error parsing packet payload", type: .error)
            return nil
        }

        if blob[Keys.end].exists() {
            if let end = blob[Keys.end].bool {
                self.end = end
            } else {
                os_log("Error parsing UDP packet end value", type: .error)
                return nil
            }

            // these fields won't be used
            self.responseLength = nil
            self.responseHash = nil
        } else if blob[Keys.responseLength].exists() && blob[Keys.responseHash].exists() {
            if let responseLength = blob[Keys.responseLength].int {
                self.responseLength = responseLength
            } else {
                os_log("Error parsing TCP packet response length", type: .error)
                return nil
            }

            // response hash can be null
            self.responseHash = blob[Keys.responseHash].stringValue

            // this field won't be used
            self.end = nil
        } else {
            os_log("Unknown packet type", type: .error)
            return nil
        }
    }
}
