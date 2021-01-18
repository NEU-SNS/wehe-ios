//
//  LocalizedStrings.swift
//  wehe
//
//  Created by Ivan Chen on 2/16/18.
//  Copyright © 2018 Northeastern University. All rights reserved.
//

import Foundation

struct LocalizedStrings {

    struct Generic {
        static let back = NSLocalizedString("Back", comment: "")
        static let differentition = NSLocalizedString("Differentiation detected", comment: "")
        static let noDifferentition = NSLocalizedString("No differentiation", comment: "")
        static let inconclusive = NSLocalizedString("Results inconclusive (please try running the test again)", comment: "")
        static let inconclusiveNoRerun = NSLocalizedString("Results inconclusive", comment: "")
        static let none = NSLocalizedString("None", comment: "")
        static let queued = NSLocalizedString("Queued", comment: "")
        static let enter = NSLocalizedString("Enter", comment: "")
        static let cancel = NSLocalizedString("Cancel", comment: "")
        static let testDone = NSLocalizedString("Done", comment: "")
        static let yes = NSLocalizedString("Yes", comment: "")
        static let no = NSLocalizedString("No", comment: "")
        static let error = NSLocalizedString("Error", comment: "")
        static let result = NSLocalizedString("Result", comment: "")
        static let retry = NSLocalizedString("Retry", comment: "")
        static let warning = NSLocalizedString("Warning", comment: "")
        static let defaultCarrier = NSLocalizedString("WiFi", comment: "")
        static let video = NSLocalizedString("Video streaming", comment: "")
        static let music = NSLocalizedString("Music streaming", comment: "")
        static let videoconferencing = NSLocalizedString("Videoconferencing", comment: "")
        static let large = NSLocalizedString("50 MB file", comment: "")
        static let small = NSLocalizedString("10 MB file", comment: "")
        static let mbps = NSLocalizedString("Mbps", comment: "")
        static let MB = NSLocalizedString("MB", comment: "")
    }

    struct App {
        static let queued = NSLocalizedString("Test queued", comment: "")
        static let loadingFiles = NSLocalizedString("Loading test files", comment: "")
        static let askingForPermission = NSLocalizedString("Contacting server", comment: "")
        static let receivedPermission = NSLocalizedString("Server granted permissions", comment: "")
        static let receivingPortMapping = NSLocalizedString("Asking server for port mapping", comment: "")
        static let originalReplay = NSLocalizedString("Running the original test", comment: "")
        static let randomReplay = NSLocalizedString("Running the randomized test", comment: "")
        static let testPortReplay = NSLocalizedString("Running the port test", comment: "")
        static let baselinePortReplay = NSLocalizedString("Running the baseline port 443 test", comment: "")
        static let finishedReplay = NSLocalizedString("Done running tests", comment: "")
        static let waitingForResults = NSLocalizedString("Requesting results from the server", comment: "")
        static let receivedResults = NSLocalizedString("Received results", comment: "")
        static let willRerun = NSLocalizedString("Results inconclusive, re-running test", comment: "")
        static let error = NSLocalizedString("Error", comment: "")
        static let block = NSLocalizedString("Test blocked", comment: "")
        static let differentiation = NSLocalizedString("Differentiation detected", comment: "")
        static let noDifferentiation = NSLocalizedString("No differentiation detected", comment: "")
        static let inconclusive = NSLocalizedString("Results inconclusive", comment: "")
        static let baselineThroughput = NSLocalizedString("Port 443 throughput", comment: "")
        static let portThroughput = NSLocalizedString("Test port throughput", comment: "")
    }

    struct MainMenu {
        static let menu = NSLocalizedString("Menu", comment: "")
        static let runTests = NSLocalizedString("Run differentiation tests", comment: "")
        static let runPortTests = NSLocalizedString("Run Port Tests", comment: "")
        static let previousResults = NSLocalizedString("Previous Results", comment: "")
        static let settings = NSLocalizedString("Settings", comment: "")
        static let viewConsentForm = NSLocalizedString("View Consent Form", comment: "")
        static let functionality = NSLocalizedString("How it Works", comment: "")
        static let viewOnlineDashboard = NSLocalizedString("View Online Dashboard", comment: "")
    }

    struct AppTable {
        static let runTests = NSLocalizedString("Run tests", comment: "")
        static let time = NSLocalizedString("Time", comment: "")
        static let size = NSLocalizedString("Total size", comment: "")
        static let portTestSize = NSLocalizedString("MB per port test)", comment: "")
        static let fileSize = NSLocalizedString("File size", comment: "")
        static let portTestsWarning = NSLocalizedString("Please select at least 2 ports to test", comment: "")
        static let wifiWarning = NSLocalizedString("If you are trying to run tests for %@, disconnect from the Wi-Fi and restart the app", comment: "")
        static let defaultMobileCareer = NSLocalizedString("your mobile carrier", comment: "")
    }
    
    struct rateAlert {
        static let title = NSLocalizedString("Please rate us", comment: "")
        static let message = NSLocalizedString("RateRequest", comment: "")
        static let yes = NSLocalizedString("Take me to App Store", comment: "")
        static let no = NSLocalizedString("No Rate", comment: "")
    }

    struct ReplayView {
        static let currentTest = NSLocalizedString("Current Test", comment: "")
        static let status = NSLocalizedString("Status", comment: "")
        static let name = NSLocalizedString("Name", comment: "")
        static let results = NSLocalizedString("Results", comment: "")
        static let nonAppThroughput = NSLocalizedString("Non-App Throughput", comment: "")
        static let start = NSLocalizedString("Start", comment: "")
        static let reRun = NSLocalizedString("Re-run", comment: "")
        static let alertArcep = NSLocalizedString("Alert Arcep", comment: "")
        static let numberOfTest = NSLocalizedString("%d of %d", comment: "")

        struct Banner {
            static let looksLikeUsingIpv6 = NSLocalizedString("Looks like your connection is using ipv6 which may not be supported", comment: "")
        }

        struct Alerts {
            static let success = NSLocalizedString("Success", comment: "")
            static let reportSent = NSLocalizedString("Report Sent", comment: "")
            static let wouldYouLikeToRerun = NSLocalizedString("Would you like to rerun the tests?", comment: "")
            static let reRunTestHuh = NSLocalizedString("Rerun Tests?", comment: "")
            static let reRunAllTestsAction = NSLocalizedString("Rerun All Tests", comment: "")
            static let reRunTestsWithErrorsAction = NSLocalizedString("Rerun Tests with Errors", comment: "")
            static let reRunDifferentiatedAction = NSLocalizedString("Rerun Tests with detected differentiation", comment: "")
            static let reRunTestsWithInconclusiveAction = NSLocalizedString("Rerun Inconclusive Tests", comment: "")
            static let warning = NSLocalizedString("Warning", comment: "")
            static let warningMessage = NSLocalizedString("This action will stop the active replay(s) and not wait for results. Existing results will be saved. Are you sure?", comment: "")
        }

        struct GlobalStatus {
            static let waitingToStart = NSLocalizedString("Waiting to start", comment: "")
            static let runningReplays = NSLocalizedString("Running test(s)", comment: "")
            static let waitingForResults = NSLocalizedString("Waiting for analysis results", comment: "")
            static let confirmationReplays = NSLocalizedString("running additional test(s)", comment: "")
            static let done = NSLocalizedString("Finished running tests", comment: "")
        }
    }

    struct PreviousResults {
        static let previousResults = NSLocalizedString("Previous Results", comment: "")
        static let appThroughput = NSLocalizedString("App Throughput", comment: "")
        static let nonAppThroughput = NSLocalizedString("Non-App Throughput", comment: "")
        static let areaThreshold = NSLocalizedString("Area Threshold", comment: "")
        static let ks2pValueThreshold = NSLocalizedString("KS2 P Value Threshold", comment: "")
        static let server = NSLocalizedString("Server", comment: "")
        static let carrier = NSLocalizedString("Carrier", comment: "")
    }

    struct ConsentForm {
        static let consentForm = NSLocalizedString("Consent Form", comment: "")
        static let consentText = NSLocalizedString("Consent Text", comment: "")
        static let accept = NSLocalizedString("Accept", comment: "")
        static let decline = NSLocalizedString("Decline", comment: "")
        static let warnindMessage = NSLocalizedString("An error occured while trying to load the web view. This could happen if the website is down or there is an issue with your connection", comment: "")
        static let backToMenu = NSLocalizedString("Back to Menu", comment: "")
        static let neuLabel = NSLocalizedString("NEU agreement text", comment: "")
        static let arcepLabel = NSLocalizedString("ARCEP agreement text", comment: "")
    }

    struct Settings {
        static let settings = NSLocalizedString("Settings", comment: "")
        static let save = NSLocalizedString("Save", comment: "")
        static let selectServer = NSLocalizedString("Select Server", comment: "")
        static let runMultipleTests = NSLocalizedString("Run multiple tests to confirm differentiation", comment: "")
        static let areaTestThreshold = NSLocalizedString("Area Test Threshold Percentage", comment: "")
        static let ks2PValue = NSLocalizedString("KS2 P Value Test Threshold Percentage", comment: "")
        static let useDefaultValues = NSLocalizedString("Use default values for settings", comment: "")
        static let custom = NSLocalizedString("Custom", comment: "")
        static let customServer = NSLocalizedString("Custom Server", comment: "")
        static let customServerUrl = NSLocalizedString("Enter the Custom Server URL", comment: "")

    }

    struct ReplayRunner {
        static let errorReadingReplay = NSLocalizedString("Error reading replay files", comment: "")
        static let errorReceivingPackets = NSLocalizedString("It seems that Wehe could not receive any result. This might be caused by your ISP blocking this test or an equipment on your local network or the server side.", comment: "")
        static let errorUnknownError = NSLocalizedString("Replay failed due to unknown error", comment: "")
        static let receiverError = NSLocalizedString("Receiver error", comment: "")
    }
    
    struct errors {
        static let connectionError = NSLocalizedString("Connection failed", comment: "")
        static let connectionBlockError = NSLocalizedString("Test blocked", comment: "")
        static let sideChannelConnectionError = NSLocalizedString("Error connecting to sidechannel", comment: "")
        static let sideChannelCreationError = NSLocalizedString("Error creating sidechannel socket", comment: "")
        static let sideChannelError = NSLocalizedString("Unknown sidechannel error", comment: "")
        static let permissionError = NSLocalizedString("Unknown permission error", comment: "")
        static let malformedPermissionError = NSLocalizedString("Received malformed permissions", comment: "")
        static let unknownPermissionError = NSLocalizedString("Unknown permission status", comment: "")
        static let unknownReplayError = NSLocalizedString("Replay does not match the replay on the server", comment: "")
        static let clientIPError = NSLocalizedString("A client with this IP is already connected", comment: "")
        static let serverResourcesError = NSLocalizedString("Server is low on resources, try again later", comment: "")
        static let replayFailedError = NSLocalizedString("Replay failed for unknown reason", comment: "")
        static let portMappingError = NSLocalizedString("Error mapping ports", comment: "")
        static let tcpError = NSLocalizedString("Failed to send TCP packet", comment: "")
        static let declearIDError = NSLocalizedString("Error declaring ID to sidechannel", comment: "")
        static let readPermissionError = NSLocalizedString("Error reading permissions", comment: "")
        static let mobileStatError = NSLocalizedString("Error sending mobile stats", comment: "")
        static let readPortMappingError = NSLocalizedString("Error reading port mapping from server", comment: "")
        static let completionMessageError = NSLocalizedString("Error sending completion message", comment: "")
        static let receiveResultError = NSLocalizedString("Error sending or receiving result message", comment: "")
    }
    
    struct aboutWehe {
        static let title = NSLocalizedString("Why Wehe", comment: "")
        static let contents = NSLocalizedString("AboutText", comment: "")
    }
    
    struct functionality {
        static let title = NSLocalizedString("How it Works", comment: "")
        static let contents = NSLocalizedString("FunctionalityText", comment: "")
    }
    
    // DPI stuff
    struct MoreInfo {
        static let title = NSLocalizedString("More Info", comment: "")
        static let unableToParseResult = NSLocalizedString("Unable to parse result", comment: "")
        static let dpiInfoResultText = NSLocalizedString("DPI Info Result Text", comment: "")
        static let noResultsFound = NSLocalizedString("No previous result found.", comment: "")
        static let unableToContactServer = NSLocalizedString("Unable to contact server", comment: "")
        static let resetDPIProgress = NSLocalizedString("Reset DPI Progress", comment: "")
        static let youWillLoseProgress = NSLocalizedString("You will lose your DPI progress and have to start over, are you sure?", comment: "")
        static let previousResult = NSLocalizedString("Previous Result:\n", comment: "")
        static let throttledBitrateInfo = NSLocalizedString("This test might be throttled. This throttling might come from your ISP or an equipment on your local network or the server side. \n\nBitrate Info\n360p:  0.4-1.0 Mbps\n480p:  0.5-2.0 Mbps\n720p:  1.5-4.0 Mbps\n1080p: 3.0-6.0 Mbps\n", comment: "")
        static let defaultInfo = NSLocalizedString("Bitrate Info\n360p:  0.4-1.0 Mbps\n480p:  0.5-2.0 Mbps\n720p:  1.5-4.0 Mbps\n1080p: 3.0-6.0 Mbps\n", comment: "")
        static let prioritizedBitrateInfo = NSLocalizedString("This test might be prioritized. This prioritization might come from your ISP or an equipment on your local network or the server side.", comment: "")
        static let blockInfo = NSLocalizedString("This test might be blocked. This blocking might come from your ISP or an equipment on your local network or the server side.", comment: "")
        static let prioritizedPortBitrateInfo = NSLocalizedString("HTTPS traffic on this port might be prioritised. This prioritization might come from your ISP, an equipment on your local network or the server side.", comment: "")
        static let throttledPortBitrateInfo = NSLocalizedString("HTTPS traffic on this port might be throttled. This throttling might come from your ISP or an equipment on your local network or the server side. \n\nBitrate Info\n360p:  0.4-1.0 Mbps\n480p:  0.5-2.0 Mbps\n720p:  1.5-4.0 Mbps\n1080p: 3.0-6.0 Mbps\n", comment: "")
        static let portBlockInfo = NSLocalizedString("HTTPS traffic on this port might be blocked. This blocking might come from your ISP or an equipment on your local network or the server side.", comment: "")
        struct BitrateInfoCell {
            static let title = NSLocalizedString("Bitrate Info", comment: "")
        }
        struct DPIInfoCell {
            static let title = NSLocalizedString("DPI Analysis Info", comment: "")
            static let beta = NSLocalizedString("beta", comment: "")
            static let infoText = NSLocalizedString("DPI Info Text", comment: "")
            static let reset = NSLocalizedString("reset", comment: "")
            static let startDPI = NSLocalizedString("Start DPI Analysis", comment: "")
        }
    }
    
    struct DPIAnalysis {
        static let title = NSLocalizedString("DPI Analysis", comment: "")
        static let replayName = NSLocalizedString("Packet %d - Bytes [%d, %d]", comment: "")
        static let start = NSLocalizedString("Start", comment: "")
        static let reRun = NSLocalizedString("Re-run", comment: "")
        struct alert {
            static let actionWillStopActiveTest = NSLocalizedString("This action will stop the active test. Are you sure?", comment: "")
            static let finished = NSLocalizedString("Test Finished", comment: "")
            static let done = NSLocalizedString("Finished running tests", comment: "")
            static let matchingKeyword = NSLocalizedString("Matching Keyword:\n\"%@\"", comment: "")
        }
        struct status {
            static let requestingNextTest = NSLocalizedString("Requesting next test", comment: "")
            static let runningAnalysis = NSLocalizedString("Running analysis", comment: "")
            static let unableToContactServer = NSLocalizedString("Unable to contact server", comment: "")
            static let error = NSLocalizedString("Error occurred", comment: "")
            static let done = NSLocalizedString("Finished running tests", comment: "")
        }
    }
}
