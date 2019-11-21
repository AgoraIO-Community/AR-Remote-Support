# AR Remote Support
This is a POC of how to build a Remote support app (similar to Vuforia Chalk) using ARKit and Agora.io's Video SDK.


## Installation
1. Clone the reposetory
2. Open reposetory folder in terminal window 
3. Run `pod install` to install all dependacies
4. Open `Keys.plist` and input your `AppID`, avaible from [https://console.agora.io](https://console.agora.io)
5. Plug in iOS devices.
6. Build and Run app on iOS devices.


## How To Use
The AR Support app is meant to be used by two users who are in two seperate physical locations. One user will input a channel name and CREATE the channel. This will launch a back facing AR enable camera. 
The second user will input the same channel name as the first user and JOIN the channel. Once both users are in the channel, the user taht "JOINED" the channele has the ability to draw on their screen, and the touch input is sent to the other user and displayed in Augmented Reality. 

Once the touch input is displayed in AR, both users can see the content.


## Dependancies
- Agora.io Video SDK: https://www.agora.io
- ARVideoKit: https://github.com/AFathi/ARVideoKit