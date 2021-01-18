//
//  Result.swift
//  wehe
//
//  Created by Kirill Voloshin on 10/31/17.
//  Copyright © 2017 Northeastern University. All rights reserved.
//
//  Stores result received from the server

import Foundation
import SwiftyJSON

class Result: NSObject, NSCoding {

    let blob: JSON
    let appName: String

    let userID: String?
    let testID: String?
    let replayName: String
    let extraString: String?
    let server: String?
    let date: Date
    let historyCount: Int
    let carrier: String
    let ipVersion: String?

    let areaThreshold: Double?
    let ks2pThreshold: Double?

    let originalAverageThroughput: Double
    let testAverageThroughput: Double

    let ks2dVal: Double
    let ks2pVal: Double
    let ks2RatioTest: Double
    let areaTest: Double

    var differentiation: DifferentiationStatus?

    var reported = false

    // for storage
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("results")

    init?(blob: JSON, appName: String, server: String?, carrier: String, ipVersion: String?, area: Double?, ks2p: Double?, differentiation: DifferentiationStatus? = nil, reported: Bool = false) {
        self.blob = blob
        self.appName = appName

        let response = blob["response"]

        userID = response["userID"].string
        testID = response["testID"].string

        if let replayName = response["replayName"].string {
            self.replayName = replayName
        } else {
            return nil
        }

        extraString = response["extraString"].string
        self.server = server
        self.carrier = carrier
        self.ipVersion = ipVersion
        self.areaThreshold = area
        self.ks2pThreshold = ks2p
        self.reported = reported

        if let date = response["date"].string {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            if let date = dateFormatter.date(from: date) {
                self.date = date
            } else {
                print("error converting date string to date")
                return nil
            }
        } else {
            return nil
        }

        if let historyCount = response["historyCount"].string {
            guard let historyCount = Int(historyCount) else {
                return nil
            }
            self.historyCount = historyCount
        } else {
            return nil
        }

        if let originalAverageThroughput = response["xput_avg_original"].string {
            guard let originalAverageThroughput = Double(originalAverageThroughput) else {
                return nil
            }

            self.originalAverageThroughput = originalAverageThroughput
        } else {
            return nil
        }

        if let testAverageThroughput = response["xput_avg_test"].string {
            guard let testAverageThroughput = Double(testAverageThroughput) else {
                return nil
            }

            self.testAverageThroughput = testAverageThroughput
        } else {
            return nil
        }

        if let ks2dVal = response["ks2dVal"].string {
            guard let ks2dVal = Double(ks2dVal) else {
                return nil
            }

            self.ks2dVal = ks2dVal
        } else {
            return nil
        }

        if let ks2pVal = response["ks2pVal"].string {
            guard let ks2pVal = Double(ks2pVal) else {
                return nil
            }

            self.ks2pVal = ks2pVal
        } else {
            return nil
        }

        if let ks2RatioTest = response["ks2_ratio_test"].string {
            guard let ks2RatioTest = Double(ks2RatioTest) else {
                return nil
            }

            self.ks2RatioTest = ks2RatioTest
        } else {
            return nil
        }

        if let areaTest = response["area_test"].string {
            guard let areaTest = Double(areaTest) else {
                return nil
            }

            self.areaTest = areaTest
        } else {
            return nil
        }

        self.differentiation = differentiation
    }

    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(blob.rawString(), forKey: "JSON")

        guard let differentiation = differentiation else {
            return
        }

        let differentiationString = differentiation.description
        aCoder.encode(differentiationString, forKey: "differentiation")

        aCoder.encode(appName, forKey: "appName")
        if let server = server {
            aCoder.encode(server, forKey: "server")
        }

        aCoder.encode(carrier, forKey: "carrier")
        aCoder.encode(reported, forKey: "reported")

        if let area = self.areaThreshold {
            aCoder.encode(area, forKey: "area")
        }

        if let ks2p = self.ks2pThreshold {
            aCoder.encode(ks2p, forKey: "ks2p")
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let blobString = aDecoder.decodeObject(forKey: "JSON") as? String else {
            print("Error decoding result json")
            return nil
        }

        var blob: JSON
        if let dataFromString = blobString.data(using: .utf8, allowLossyConversion: false) {
            do {
                blob = try JSON(data: dataFromString)
            } catch {
                print("Error parsing result json")
                return nil
            }
        } else {
            return nil
        }

        let differentiationString = aDecoder.decodeObject(forKey: "differentiation") as? String ?? ""
        var differentiation: DifferentiationStatus?

        switch differentiationString {
        case DifferentiationStatus.differentiation.description:   differentiation = .differentiation
        case DifferentiationStatus.noDifferentiation.description: differentiation = .noDifferentiation
        case DifferentiationStatus.inconclusive.description:      differentiation = .inconclusive
        default:                                                  differentiation = nil
        }

        guard let appName = aDecoder.decodeObject(forKey: "appName") as? String else {
            print("Error decoding result app name")
            return nil
        }
        var carrier = "unknown"
        if aDecoder.containsValue(forKey: "carrier") {
            if let c = aDecoder.decodeObject(forKey: "carrier") as? String {
                carrier = c
            }
        }
        
        let settings = Globals.settings
        let ipVersion = settings.ipVersion
        let server = aDecoder.decodeObject(forKey: "server") as? String
        let reported = aDecoder.decodeBool(forKey: "reported")
        var area: Double? = aDecoder.decodeDouble(forKey: "area")
        var ks2p: Double? = aDecoder.decodeDouble(forKey: "ks2p")
        area = area == 0 ? nil : area
        ks2p = ks2p == 0 ? nil : ks2p

        self.init(blob: blob, appName: appName, server: server, carrier: carrier, ipVersion: ipVersion, area: area, ks2p: ks2p, differentiation: differentiation, reported: reported)

    }
}
