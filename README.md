# AR Remote Support
This is a POC app for how to build a remote support app (similar to Vuforia Chalk) using ARKit and Agora.io's Video SDK.

## Installation
1. Clone the repository
2. Open repository folder in terminal window 
3. Run `pod install` to install all dependencies
4. Open the ` .xcworkspace` file in Xcode
5. Open `Keys.plist` and input your `AppID`, available from [https://console.agora.io](https://console.agora.io)
6. Plug in iOS devices.
7. Build and Run app on iOS devices.

## Device Requirements
This app works with any iOS device that supports ARKit 
- iPhone (6S or newer)
- iPad (5th Generation or newer)

To properly run this demo, you will need 2 physical iOS devices. You can not run all the features of this app through the simulator. 

## How To Use
The AR Remote Video Support app is meant to be used by two users who are in two seperate physical locations. One user will input a channel name and CREATE the channel. This will launch a back facing AR enable camera. 
The second user will input the same channel name as the first user and JOIN the channel. Once both users are in the channel, the user that "JOINED" the channel has the ability to draw on their screen, and the touch input is sent to the other user and displayed in Augmented Reality. 

## Dependancies
- Agora.io Video SDK: https://www.agora.io
- ARVideoKit: https://github.com/AFathi/ARVideoKit
