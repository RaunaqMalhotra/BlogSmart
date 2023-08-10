//
//  SceneDelegate.swift
//  BlogSmart
//
//  Created by Raunaq Malhotra on 4/13/23.
//

import UIKit
import ParseSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    private enum Constants {
        static let loginNavigationControllerIdentifier = "LoginNavigationController"
        static let readNavigationControllerIdentifier = "ReadNavigationController"
        static let writeNavigationControllerIdentifier  = "WriteNavigationController"
        static let storyboardIdentifier = "Main"
    }

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("login"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.login()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("logout"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.logOut()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("Go back to the initial screen"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.completePost()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("Navigate to write screen"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.writePost()
        }

        // Check for cached user for persisted log in.
        if User.current != nil {
            login()
        }
    }
    
    // go to ReadViewController
    private func login() {
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.readNavigationControllerIdentifier)
    }
    
    private func logOut() {
        User.logout { [weak self] result in
            switch result {
            case .success:
                
                // Make sure UI updates are done on main thread when initiated from background thread.
                DispatchQueue.main.async {
                    
                    // Instantiate the storyboard that contains the destination view controller
                    let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
                    
                    // Instantiate the destination view controller
                    let viewController = storyboard.instantiateViewController(withIdentifier: Constants.loginNavigationControllerIdentifier)
                    
                    // Programatically set the current displayed view controller
                    self?.window?.rootViewController = viewController
                }
            case .failure(let error):
                print("❌ Log out error: \(error)")
            }
        }
    }
    
    private func completePost() {
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.readNavigationControllerIdentifier)
    }
    
    private func writePost() {
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.writeNavigationControllerIdentifier)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

