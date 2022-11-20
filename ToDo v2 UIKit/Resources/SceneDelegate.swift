//
//  SceneDelegate.swift
//  ToDo v2 UIKit
//
//  Created by Alex Hwan on 18.11.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        let navController = UINavigationController(rootViewController: ListsViewController())
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        CoreDataManager.sharedManager.saveContext()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        CoreDataManager.sharedManager.saveContext()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        CoreDataManager.sharedManager.saveContext()
    }
    
    
}

