//
//  AppDelegate.swift
//  BareExpo
//
//  Created by the Expo team on 5/27/20.
//  Copyright © 2020 Expo. All rights reserved.
//

import Foundation
import ExpoModulesCore
import EXDevMenuInterface
#if EX_DEV_MENU_ENABLED
import EXDevMenu
#endif

#if FB_SONARKIT_ENABLED && canImport(FlipperKit)
import FlipperKit
#endif

@UIApplicationMain
class AppDelegate: ExpoAppDelegate, RCTBridgeDelegate {
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    initializeFlipper(with: application)

    let bridge = reactDelegate.createBridge(with: self, launchOptions: launchOptions)
    let rootView = reactDelegate.createRootView(with: bridge, moduleName: "main", initialProperties: nil)
    let rootViewController = reactDelegate.createRootViewController()
    rootView.backgroundColor = UIColor.white
    rootViewController.view = rootView

    window = UIWindow(frame: UIScreen.main.bounds)
    window!.rootViewController = rootViewController
    window!.makeKeyAndVisible()

    super.application(application, didFinishLaunchingWithOptions: launchOptions)

    return true
  }
  
  #if RCT_DEV
  func bridge(_ bridge: RCTBridge!, didNotFindModule moduleName: String!) -> Bool {
    return true
  }
  #endif
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if (super.application(app, open: url, options: options)) {
      return true
    }
    return RCTLinkingManager.application(app, open: url, options: options)
  }
  
  private func initializeFlipper(with application: UIApplication) {
  #if FB_SONARKIT_ENABLED && canImport(FlipperKit)
    let client = FlipperClient.shared()
    let layoutDescriptorMapper = SKDescriptorMapper(defaults: ())
    client?.add(FlipperKitLayoutPlugin(rootNode: application, with: layoutDescriptorMapper!))
    client?.add(FKUserDefaultsPlugin(suiteName: nil))
    client?.add(FlipperKitReactPlugin())
    client?.add(FlipperKitNetworkPlugin(networkAdapter: SKIOSNetworkAdapter()))
    client?.start()
  #endif
  }

  // MARK: - RCTBridgeDelegate

  func sourceURL(for bridge: RCTBridge!) -> URL! {
    // DEBUG must be setup in Swift projects: https://stackoverflow.com/a/24112024/4047926
    #if DEBUG
    return RCTBundleURLProvider.sharedSettings()?.jsBundleURL(forBundleRoot: "index", fallbackResource: nil)
    #else
    return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
    #endif
  }

  func extraModules(for bridge: RCTBridge!) -> [RCTBridgeModule] {
    var extraModules = [RCTBridgeModule]()
    // You can inject any extra modules that you would like here, more information at:
    // https://facebook.github.io/react-native/docs/native-modules-ios.html#dependency-injection

    // RCTDevMenu was removed when integrating React with Expo client:
    // https://github.com/expo/react-native/commit/7f2912e8005ea6e81c45935241081153b822b988
    // Let's bring it back in Bare Expo.
    extraModules.append(RCTDevMenu() as! RCTBridgeModule)

    // Add AsyncStorage back to the project
    // https://github.com/expo/react-native/commit/bd1396034319e6e59f960fac7aeca1f483c2052d
    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
    let storageDirectory = documentDirectory.appendingPathComponent("RCTAsyncLocalStorage_V1")
    extraModules.append(RCTAsyncLocalStorage(storageDirectory: storageDirectory))
    return extraModules
  }
}
