import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()
    reactNativeDelegate = delegate
    reactNativeFactory = factory
    window = UIWindow(frame: UIScreen.main.bounds)
    factory.startReactNative(withModuleName: "AutoSaleUmar", in: window, launchOptions: launchOptions)
    return true
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard url.scheme == "autosaleumar" else { return false }
    if url.host == "metro-reset" {
      UserDefaults.standard.removeObject(forKey: "ASUMetroBaseURL")
      return true
    }
    if url.host == "metro",
       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let value = components.queryItems?.first(where: { $0.name == "url" })?.value,
       let parsed = URL(string: value),
       parsed.scheme == "https" {
      UserDefaults.standard.set(value.trimmingCharacters(in: CharacterSet(charactersIn: "/")), forKey: "ASUMetroBaseURL")
      return true
    }
    return false
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? { bundleURL() }

  override func bundleURL() -> URL? {
#if DEBUG
    if let base = UserDefaults.standard.string(forKey: "ASUMetroBaseURL"),
       !base.isEmpty,
       var components = URLComponents(string: base + "/index.bundle") {
      components.queryItems = [
        URLQueryItem(name: "platform", value: "ios"),
        URLQueryItem(name: "dev", value: "true"),
        URLQueryItem(name: "minify", value: "false"),
        URLQueryItem(name: "modulesOnly", value: "false"),
        URLQueryItem(name: "runModule", value: "true")
      ]
      if let remoteURL = components.url { return remoteURL }
    }
    if let bundled = Bundle.main.url(forResource: "main", withExtension: "jsbundle") { return bundled }
    return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
