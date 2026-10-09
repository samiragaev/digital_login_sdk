import AuthenticationServices
import Flutter
import UIKit

/// Runs the DigitalLogin authorization in an `ASWebAuthenticationSession`.
///
/// The session only sees redirects that happen inside its own browser. When
/// the user signs in through another app (for example mygov), that app opens
/// the redirect URI through the system instead, and it reaches the app
/// delegate or scene delegate. This plugin listens there too, completes the
/// pending authorization with that URL and dismisses the session.
public final class DigitalLoginSdkPlugin: NSObject, FlutterPlugin {
  private var session: ASWebAuthenticationSession?
  private var pendingResult: FlutterResult?
  private var redirectUri: URLComponents?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "digital_login_sdk", binaryMessenger: registrar.messenger())
    let instance = DigitalLoginSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
    registrar.addSceneDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "authorize":
      authorize(arguments: call.arguments as? [String: Any], result: result)
    case "cancel":
      finish(with: FlutterError.canceled)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Authorization

  private func authorize(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "IN_PROGRESS", message: "An authorization is already in progress.", details: nil))
      return
    }
    guard
      let urlString = arguments?["url"] as? String,
      let url = URL(string: urlString),
      let redirectString = arguments?["redirectUri"] as? String,
      let redirect = URLComponents(string: redirectString),
      let scheme = redirect.scheme
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "url and redirectUri are required.", details: nil))
      return
    }

    let session: ASWebAuthenticationSession
    if #available(iOS 17.4, *), scheme == "https", let host = redirect.host {
      session = ASWebAuthenticationSession(
        url: url,
        callback: .https(host: host, path: redirect.path.isEmpty ? "/" : redirect.path),
        completionHandler: { [weak self] url, error in self?.sessionCompleted(url: url, error: error) })
    } else {
      session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: scheme,
        completionHandler: { [weak self] url, error in self?.sessionCompleted(url: url, error: error) })
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = arguments?["preferEphemeral"] as? Bool ?? false

    pendingResult = result
    redirectUri = redirect
    self.session = session

    if !session.start() {
      finish(with: FlutterError(code: "START_FAILED", message: "Could not start the login session.", details: nil))
    }
  }

  private func sessionCompleted(url: URL?, error: Error?) {
    if let url = url {
      finish(with: url.absoluteString)
    } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
      finish(with: FlutterError.canceled)
    } else {
      finish(with: FlutterError(code: "FAILED", message: error?.localizedDescription, details: nil))
    }
  }

  /// Completes the pending call exactly once and closes the session.
  private func finish(with value: Any) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    redirectUri = nil
    let session = self.session
    self.session = nil
    // Cancelling calls the completion handler again with `canceledLogin`;
    // `pendingResult` is already nil, so that second call is ignored.
    session?.cancel()
    result(value)
  }

  // MARK: - Redirects from other apps

  /// Accepts [url] if an authorization is pending and it targets the redirect URI.
  private func handleIncoming(_ url: URL) -> Bool {
    guard pendingResult != nil, let redirect = redirectUri, matches(url, redirect) else {
      return false
    }
    finish(with: url.absoluteString)
    return true
  }

  private func matches(_ url: URL, _ redirect: URLComponents) -> Bool {
    func normalized(_ path: String) -> String {
      path.hasSuffix("/") ? String(path.dropLast()) : path
    }
    guard let incoming = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
    return incoming.scheme?.lowercased() == redirect.scheme?.lowercased()
      && (incoming.host ?? "").lowercased() == (redirect.host ?? "").lowercased()
      && normalized(incoming.path) == normalized(redirect.path)
  }

  public func application(
    _ application: UIApplication, open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    handleIncoming(url)
  }

  public func application(
    _ application: UIApplication, continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]) -> Void
  ) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    else { return false }
    return handleIncoming(url)
  }
}

// MARK: - Scene based apps

extension DigitalLoginSdkPlugin: FlutterSceneLifeCycleDelegate {
  public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    URLContexts.contains { handleIncoming($0.url) }
  }

  public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    else { return false }
    return handleIncoming(url)
  }
}

// MARK: - Presentation

extension DigitalLoginSdkPlugin: ASWebAuthenticationPresentationContextProviding {
  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    return windows.first { $0.isKeyWindow }
      ?? windows.first
      ?? (UIApplication.shared.delegate?.window ?? nil)
      ?? ASPresentationAnchor()
  }
}

extension FlutterError {
  fileprivate static var canceled: FlutterError {
    FlutterError(code: "CANCELED", message: "The user cancelled the login.", details: nil)
  }
}
