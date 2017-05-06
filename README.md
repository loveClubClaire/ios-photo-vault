# Photo Vault 1.1
A photo vault application for iOS, programmed in Swift 3. The idea was to provide an ad-free photo vault application with a look and feel similar to the iOS Photos app. 

## Major features include:
* `Image support` 
* `Video support`
* `Gif support`: Animated images move when displayed
* `TouchID protected` 

# Supporting Projects
This application uses 

https://github.com/bahlo/SwiftGif --> a Swift extension for gif support 

https://github.com/MailOnline/ImageViewer --> an image viewer project used for displaying and scrolling through images. 

# Misc
The original intention of this project was to use pods. It turned out the ImageViewer needed heavy customization to work. So I did a bad thing and just edited the pod files and uploaded the pods to GitHub in this project. This project should compile when you download it, without the need to run CocoaPods. Don't run CocoaPods at all because that would remove the modified ImageViewer classes this project needs. I should clean this up at some point. 
