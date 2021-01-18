//
//  Helper.swift
//  wehe
//
//  Created by Kirill Voloshin on 10/11/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreTelephony
import SystemConfiguration
import Socket
import Alamofire
import NSData_FastHex

class Helper {
    static func readJSONFile(filename: String) -> JSON? {
        if let path = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                let data = try Data(contentsOf: path, options: .alwaysMapped)
                var jsonObj: JSON
                do {
                    jsonObj = try JSON(data: data)
                } catch {
                    print("Error parsing json")
                    return nil
                }
                if jsonObj != JSON.null {
                    return jsonObj
                } else {
                    print("Could not get json from file, make sure that file contains valid json.")
                    return nil
                }
            } catch let error {
                print(error.localizedDescription)
                return nil
            }
        } else {
            print("Invalid filename/path: " + filename)
            return nil
        }
    }
    static func getMobileStats(settings: Settings) -> String? {
        
        var deviceInfo = JSON()
        
        deviceInfo["manufacturer"].string = "Apple"
        
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            deviceInfo["model"].string = simulatorModelIdentifier
        } else {
            var sysinfo = utsname()
            uname(&sysinfo)
            deviceInfo["model"].string = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        }
        
        deviceInfo["carrierName"].string = getCarrier() ?? "nil"
        
        var networkTechnologyString = ""
        switch getReachability() {
        case .notReachable: networkTechnologyString = "nil"
        case .reachableViaWWAN: networkTechnologyString = "LTE"
        case .reachableViaWiFi:
            networkTechnologyString = "WIFI"
            deviceInfo["carrierName"].string = "WIFI"
        }
        
        deviceInfo["networkType"].string = networkTechnologyString
        deviceInfo["cellInfo"].string = "nil"
        
        var osInfo = JSON()
        osInfo["INCREMENTAL"].string = "0"
        osInfo["RELEASE"].string = UIDevice.current.systemVersion
        osInfo["SDK_INT"].string = "0"
        deviceInfo["os"] = osInfo
        
        var location = JSON()
        location["latitude"].string = settings.latitude ?? "nil"
        location["longitude"].string = settings.longitude ?? "nil"
        deviceInfo["locationInfo"] = location
        
//         mobileStats["deviceInfo"] = deviceInfo
        if let parsed = deviceInfo.rawString() {
            return parsed.removingWhitespaces()
        } else {
            return nil
        }
        
    }
    
    static func runOnUIThread(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    static func isFrenchLocale() -> Bool {
        // devide local language
        let locale = NSLocale.current.languageCode
        // app local language
        let pre = Locale.preferredLanguages[0]
        
        return (locale! == "fr" || pre == "fr")
    }
    
    static func jsonToApps(json: JSON) -> [App] {
        var apps = [App]()

        guard json["apps"] != JSON.null else {
            print("apps key not found in JSON")
            return apps
        }

        for (_, value) in json["apps"] {

            // don't show non French tests if French Locale
            if isFrenchLocale() {
                if value["englishOnly"].bool ?? false {
                    continue
                }
            } else {
                if value["frenchOnly"].bool ?? false {
                    continue
                }
            }

            let hidden = value["hidden"].bool

            if hidden ?? false {
                continue
            }

            let name = value["name"].stringValue
            let size = value["size"].string
            let time = value["time"].doubleValue
            let icon = value["icon"].string
            let replayFile = value["replayFile"].stringValue
            let randomReplayFile = value["randomReplayFile"].stringValue
            let portTest = value["portTest"].boolValue
            let largeTest = value["largeTest"].boolValue
            let appType = value["appType"].string
            let app = App(name: name, size: size, time: time, icon: icon, replayFile: replayFile, randomReplayFile: randomReplayFile, isPortTest: portTest, isLargeTest: largeTest, appType: appType)

            if let app = app {
                apps.append(app)
            }
        }

        return apps
    }

    static func loadResults() -> [Result] {
        let loadedResults = NSKeyedUnarchiver.unarchiveObject(withFile: Result.ArchiveURL.path) as? [Result]
        if let unwrappedResults = loadedResults {
            let sortedResults = unwrappedResults.sorted {
                return $0.date > $1.date
            }
            return sortedResults
        } else {
            return [Result]()
        }
    }

    static func hexStringToData(from hexString: String) -> Data? {
        let fastData = NSData(hexString: hexString) as Data
        
        return fastData
    }
    
    static func flipHex(_ hex: String, left: Int = -1, right: Int = -1) -> String {
        let data = hexStringToData(from: hex)!
        let ascii = String(data: data, encoding: .ascii)!
        var flippedHex = ""
        for (i, c) in ascii.utf16.enumerated() {
            let originalBinary = String(c, radix: 2)
            let charHex: String
            if i >= left && i < right {
                var flippedBinary = ""
                for b in originalBinary {
                    flippedBinary += b == "0" ? "1" : "0"
                }
                charHex = binToHex(pad(string: flippedBinary, toSize: 8))!
            } else {
                charHex = binToHex(pad(string: originalBinary, toSize: 8))!
            }
            flippedHex += charHex
        }
        return flippedHex
    }
    
    static func pad(string: String, toSize: Int) -> String {
        var padded = string
        for _ in 0..<(toSize - string.count) {
            padded = "0" + padded
        }
        return padded
    }
    
    static func binToHex(_ bin: String) -> String? {
        // binary to integer:
        guard let num = UInt16(bin, radix: 2) else { return nil }
        // integer to hex:
        let hex = String(num, radix: 16, uppercase: false) // (or false)
        return pad(string: hex, toSize: 2)
    }

    static func dnsLookup(hostname: String) -> String? {
        let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                return numAddress
            }
        }
        return nil
    }
    
    static func getIPProtocol(ip: String) -> Socket.ProtocolFamily {
        if ip.components(separatedBy: ".").count == 4 {
            return Socket.ProtocolFamily.inet
        } else if ip.components(separatedBy: ":").count > 0 {
            return Socket.ProtocolFamily.inet6
        } else {
            // default to ipv4 for now (for example, dns failed and we just got the hostname)
            return Socket.ProtocolFamily.inet
        }
    }
    
    static func getReachability() -> ReachabilityStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        } else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        } else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        } else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        } else {
            return .notReachable
        }
    }
    
    static func isOnWiFi() -> Bool {
        switch getReachability() {
        case .reachableViaWiFi: return true
        default:                return false
        }
    }
    
    static func getCarrier() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.subscriberCellularProvider {
            return carrier.carrierName
        } else {
            return nil
        }
    }
    
    static func makeURL(ip: String, port: String, api: String, https: Bool = false) -> String {
        let ip = getIPProtocol(ip: ip) == .inet6 ? "[\(ip)]" : ip
        if https {
            return "https://\(ip):\(port)/\(api)"
        } else {
            return "http://\(ip):\(port)/\(api)"
        }
    }
    
    static func colorFromRGB(r: Int, g: Int, b: Int) -> UIColor {
        return UIColor( red: CGFloat(Double(r)/255.0), green: CGFloat(Double(g)/255.0), blue: CGFloat(Double(b)/255.0), alpha: CGFloat(1.0) )
    }
    
    static func loadCert() -> [SecCertificate] {
        var certs: [SecCertificate] = []
        let certName = "ca"
        if let pinnedCertificateURL = Bundle.main.url(forResource: certName, withExtension: "der") {
            do {
                let pinnedCertificateData = try Data(contentsOf: pinnedCertificateURL) as CFData
                if let pinnedCertificate = SecCertificateCreateWithData(nil, pinnedCertificateData) {
                    certs.append(pinnedCertificate)
                } else {
                    print("error creating certificate from " + certName)
                }
            } catch _ {
                print("error loading cert")
            }
        }
        
        return certs
    }

    static func getServerTrustManager(server: String) -> ServerTrustManager {
        let evaluators: [String: ServerTrustEvaluating] = [
            server: PinnedCertificatesTrustEvaluator(certificates: loadCert(), acceptSelfSignedCertificates: true, performDefaultValidation: false, validateHost: false)
        ]

        let manager = ServerTrustManager(evaluators: evaluators)
        return manager
    }
}

enum ReachabilityStatus {
    case notReachable
    case reachableViaWWAN
    case reachableViaWiFi
}
