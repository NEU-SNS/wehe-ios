//
//  Replay.swift
//  wehe
//
//  Created by Kirill Voloshin on 10/10/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
// Load replay json and store it

import Foundation
import SwiftyJSON
import os.log

class Replay {
    let name: String
    let port: String
    let type: ReplayProtocol
    var packets = [Packet]()

    // TCP only
    var destinationIP: String?

    init?(blob: JSON, testRegion: TestRegion? = nil) {
        if let name = blob[3].string {
            self.name = name
        } else {
            os_log("Error getting replay name", type: .error)
            return nil
        }

        let udpPorts = blob[1].arrayValue
        let tcpPorts = blob[2].arrayValue

        if udpPorts.count > 0 {
            if let port = udpPorts[0].string {
                self.port = port
            } else {
                os_log("Error parsing UDP port", type: .error)
                return nil
            }
            self.type = .udp
        } else if tcpPorts.count > 0 {
            guard let destinationString = tcpPorts[0].string?.components(separatedBy: "-").last else {
                print("Error parsing TCP destination string")
                return nil
            }

            var destinationArray = destinationString.components(separatedBy: ".")
            guard destinationArray.count != 4 else {
                print("Malformed destination string")
                return nil
            }

            self.port = destinationArray.removeLast()
            self.destinationIP = destinationArray.joined(separator: ".")

            self.type = .tcp
        } else {
            os_log("No port information found", type: .error)
            return nil
        }

        let packets = blob[0].arrayValue
        if packets.count == 0 {
            os_log("No packets found in the replay", type: .error)
            return nil
        }

        for (packetNum, packetJSON) in packets.enumerated() {
            let packet: Packet?
            if let testRegion = testRegion, packetNum + 1 == testRegion.numPacket {
                packet = Packet(blob: packetJSON, bound: (left: testRegion.left, right: testRegion.right))
            } else {
                packet = Packet(blob: packetJSON)
            }
            if let packet = packet {
                self.packets.append(packet)
            } else {
                os_log("Error parsing packet for replay", type: .error)
                return nil
            }
        }

    }
}

enum ReplayProtocol {
    case udp
    case tcp
}
