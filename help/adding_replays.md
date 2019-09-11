# Adding replays to the iOS app

## 1. Adding files to the project

* Place the json files into the `Replay_files` folder
* In Xcode, right click on `json.bundle` and select `Add Files to "wehe"...`

## 2. Adding replay to the app

* If the app does not have an icon uploaded, add a 512 × 512 png image to `apps` in `Assets.xcassets` in xcode
* Open `app_list.json` in `json.bundle` and either add a new entry or edit an existing one

Replay format:
```json
 {
    "name" : "Youtube", // the name that will be shown to the user
    "size" : "10.4", // size of the replay file, not used in calculations
    "time" : 4.05, // time the replay will take, used when calculating time slices
    "icon" : "youtube", // the name of the icon that will be used for the replay
    "replayFile" : "Youtube.pcap_client_all", // original replay file
    "randomReplayFile" : "YoutubeRandom.pcap_client_all" // random replay file
    }
```

## 3. Releasing an update

* Open `Info.plist` in xcode and bump the `Bundle versions string, short` value
* Select `Generic iOS Device` in the top left of xcode as the compile target
* Run `product` -> `archive` from the top bar menu of MacOS
* Follow the steps to upload the archive to the app store
* Go to the [iTunes Connect](https://itunesconnect.apple.com/) page to publish an update