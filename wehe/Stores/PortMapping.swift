//
//  PortMapping.swift
//  wehe
//
//  Created by Work on 10/18/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import Foundation
import SwiftyJSON

class PortMapping {
    let tcpMap: JSON
    let udpMap: JSON

    init?(blob: JSON) {
        guard blob["udp"].exists() && blob["tcp"].exists() else {
            return nil
        }

        udpMap = blob["udp"]
        tcpMap = blob["tcp"]
    }

    func getPortMapping(ip: String, port: String, prot: ReplayProtocol) -> ServerPortPair? {
        var map: JSON
        switch prot {
        case .udp: map = udpMap
        case .tcp: map = tcpMap
        }

        guard map[ip][port].exists() else {
            return nil
        }

        guard let portMap = map[ip][port].array else {
            return nil
        }

        guard portMap.count == 2 else {
            return nil
        }

        let ip = portMap[0].stringValue
        guard let port = portMap[1].int else {
            return nil
        }

        return ServerPortPair(ip: ip, port: Int32(port))
    }
}

struct ServerPortPair {
    var ip: String
    let port: Int32
}
