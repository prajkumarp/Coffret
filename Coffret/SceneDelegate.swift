//
//  SceneDelegate.swift
//  Coffret
//
//  Created by Rajkumar on 29/06/25.
//

import UIKit

/**
 Scene delegate responsible for managing the app's UI lifecycle.
 
 This class handles scene-based lifecycle events and manages the main window
 for the Coffret FTP Server application. It provides methods for handling
 scene transitions and state management.
 
 - Author: Rajkumar
 - Version: 1.0
 - Date: 29/06/25
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// The main window for this scene
    var window: UIWindow?

    // MARK: - Scene Lifecycle Methods

    /**
     Called when the scene connects to the session.
     
     This method configures and attaches the UIWindow to the provided UIWindowScene.
     It sets up the initial view controller from the main storyboard.
     
     - Parameters:
        - scene: The scene object being connected
        - session: The scene session
        - connectionOptions: Options associated with the scene connection
     */
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Configure the main window
        window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }

    /**
     Called when the scene is being released by the system.
     
     This occurs shortly after the scene enters the background, or when its session
     is discarded. Release any resources associated with this scene that can be
     re-created the next time the scene connects.
     
     - Parameter scene: The scene being disconnected
     */
    func sceneDidDisconnect(_ scene: UIScene) {
        // Release scene-specific resources
    }

    /**
     Called when the scene moves from an inactive state to an active state.
     
     Use this method to restart any tasks that were paused (or not yet started)
     when the scene was inactive.
     
     - Parameter scene: The scene that became active
     */
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart paused tasks and refresh UI
    }

    /**
     Called when the scene will move from an active state to an inactive state.
     
     This may occur due to temporary interruptions (ex. an incoming phone call).
     
     - Parameter scene: The scene that will become inactive
     */
    func sceneWillResignActive(_ scene: UIScene) {
        // Pause ongoing tasks and disable timers
    }

    /**
     Called as the scene transitions from the background to the foreground.
     
     Use this method to undo the changes made on entering the background.
     
     - Parameter scene: The scene entering the foreground
     */
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Refresh UI and restart background tasks
    }

    /**
     Called as the scene transitions from the foreground to the background.
     
     Use this method to save data, release shared resources, and store enough
     scene-specific state information to restore the scene back to its current state.
     
     - Parameter scene: The scene entering the background
     */
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save user data and release resources
    }
}

