import Flutter
import SpotifyLogin

public class SwiftSpotifySdkPlugin: NSObject, FlutterPlugin {
    
    private static var instance = SwiftSpotifySdkPlugin()

    private static var playerStateChannel: FlutterEventChannel?
    private static var playerContextChannel: FlutterEventChannel?
    
    private var sessionManager: SessionManager?


    public static func register(with registrar: FlutterPluginRegistrar) {
        guard playerStateChannel == nil else {
            // Avoid multiple plugin registations
            return
        }
        let spotifySDKChannel = FlutterMethodChannel(name: "spotify_sdk", binaryMessenger: registrar.messenger())
        let connectionStatusChannel = FlutterEventChannel(name: "connection_status_subscription", binaryMessenger: registrar.messenger())
        playerStateChannel = FlutterEventChannel(name: "player_state_subscription", binaryMessenger: registrar.messenger())
        playerContextChannel = FlutterEventChannel(name: "player_context_subscription", binaryMessenger: registrar.messenger())
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: spotifySDKChannel)
        
        
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {
        case SpotifySdkConstants.methodGetAccessToken:
            guard let swiftArguments = call.arguments as? [String:Any],
                  let clientID = swiftArguments[SpotifySdkConstants.paramClientId] as? String,
                  !clientID.isEmpty else {
                result(FlutterError(code: "Argument Error", message: "Client ID is not set", details: nil))
                return
            }

            guard let url = swiftArguments[SpotifySdkConstants.paramRedirectUrl] as? String,
                  !url.isEmpty else {
                result(FlutterError(code: "Argument Error", message: "Redirect URL is not set", details: nil))
                return
            }

            


            let accessToken: String? = swiftArguments[SpotifySdkConstants.paramAccessToken] as? String
            let spotifyUri: String = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String ?? ""

            do {
                try connectToSpotify(clientId: clientID, redirectURL: url, accessToken: accessToken, spotifyUri: spotifyUri, asRadio: swiftArguments[SpotifySdkConstants.paramAsRadio] as? Bool, additionalScopes: swiftArguments[SpotifySdkConstants.scope] as? String)
            }
            catch SpotifyError.redirectURLInvalid {
                result(FlutterError(code: "errorConnecting", message: "Redirect URL is not set or has invalid format", details: nil))
            }
            catch {
                result(FlutterError(code: "CouldNotFindSpotifyApp", message: "The Spotify app is not installed on the device", details: nil))
                return
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func connectToSpotify(clientId: String, redirectURL: String, accessToken: String? = nil, spotifyUri: String = "", asRadio: Bool?, additionalScopes: String? = nil) throws {
        
        typealias LoginSessionManager = SessionManager
        typealias LoginConfiguration = Configuration
        
        let config = LoginConfiguration(clientID: clientId, redirectURLString: redirectURL)
        sessionManager = LoginSessionManager(configuration: config)
        let sessionHandler = SessionManagerHandler()
        sessionManager?.delegate = sessionHandler
        
        sessionManager?.startAuthorizationCodeProcess(with: [.playlistModifyPrivate, .playlistModifyPublic, .playlistReadCollaborative, .playlistReadPrivate, .userLibraryRead, .userLibraryModify])
    }
}

extension SwiftSpotifySdkPlugin {
    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let result = sessionManager?.openURL(url) else {return true}
        return true
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
           
            return false
        }
        
        guard let result = sessionManager?.openURL(url) else {return true}
        return true
    }
}
