# Getting Started

## Requirements

 * xcode supporting swift 4
 * [cocoapods](https://cocoapods.org/) for dependancy management

 ## Preparing the repository

 1. Clone the repository
 1. Navigate to the repository in your terminal and run `pod install` (note: this can take around 5-10 minutes, be patient)
 1. After the installion is done, open the repository in xcode <b> by clicking the `wehe.xcworkspace` file </b>. This is important, opening the repository through xcode for the first time may cause the dependencies to not be detected and produce errors

 ## Submitting a build to the app store

 1. Go to `xcode` -> `preferences` -> `accounts` and login with the `wehe@ccs.neu.edu` apple id account
 1.  If an error occurs during compilation, click on it and make the appropriate changes (for example, you may have to set the signing group. since you are logged in you should be able to just select an existing signing group). 
 1.  Select `generic iOS device` as your compilation target in the top left corner of xcode
 1.  Go to `product` -> `archive`
 1.  Follow the instructions. If a certificate error occurs, click through to manage certificates and press the `+` sign to generate a new certificate
 1.  You can manage the submitted builds at the [iTunes connect pannel](https://itunesconnect.apple.com/)