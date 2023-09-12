//
//  SoundNavigationApp.swift
//  SoundNavigation
//
//  Created by Jason on 2023/9/9.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI
import FirebaseCore
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct SoundNavigationApp: App {
    
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    static var playingAvailable:Bool = false
    
    init() {
        GMSServices.provideAPIKey("AIzaSyBIy0SAXuXjbGpz9B2lZu-4wC_7ShSl7Ak")
    }
    
    var body: some Scene {
        WindowGroup{
            ContentView()
        }
    }
}
