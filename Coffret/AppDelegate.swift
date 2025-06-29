//
//  AppDelegate.swift
//  Coffret
//
//  Created by Rajkumar on 29/06/25.
//

import UIKit

/**
 The main application delegate for Coffret - an iOS FTP Server application.
 
 This class handles the application lifecycle and manages the scene-based architecture
 for iOS 13+ devices. It serves as the entry point for the application and handles
 system-level events and configurations.
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Application Lifecycle
    
    /**
     Called when the application finishes launching.
     
     This method is called after the application has been launched and allows for
     any necessary initialization before the application becomes active.
     
     - Parameters:
        - application: The singleton app object
        - launchOptions: A dictionary containing information about why the app was launched
     
     - Returns: `true` if the app launch should proceed, `false` otherwise
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: - UISceneSession Lifecycle

    /**
     Provides the configuration for a new scene session.
     
     Called when a new scene session is being created. Use this method to select
     a configuration to create the new scene with.
     
     - Parameters:
        - application: The singleton app object
        - connectingSceneSession: The scene session being connected
        - options: Options containing information about the scene connection
     
     - Returns: A scene configuration object containing the information needed to create the scene
     */
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /**
     Called when the user discards scene sessions.
     
     This method is called when the user discards a scene session. If any sessions
     were discarded while the application was not running, this will be called shortly
     after application:didFinishLaunchingWithOptions. Use this method to release any
     resources that were specific to the discarded scenes.
     
     - Parameters:
        - application: The singleton app object
        - sceneSessions: The set of scene sessions that were discarded
     */
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Release any resources associated with the discarded scenes
    }
}

