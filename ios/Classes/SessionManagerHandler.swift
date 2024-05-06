//
//  SessionManagerDelegate.swift
//  spotify_sdk
//
//  Created by Yevhen Lavrynenko on 03.05.2024.
//

import Foundation
import SpotifyLogin

class SessionManagerHandler: StatusHandler, SessionManagerDelegate {
    
    var tokenResult: FlutterResult?
    
    func sessionManager(manager: SpotifyLogin.SessionManager, didFailWith error: any Error) {
        eventSink?("{\"connected\": false, \"errorCode\": \"\(error._code)\", \"errorDetails\": \"\(error.localizedDescription)\"}")
    }
    
    func sessionManager(manager: SpotifyLogin.SessionManager, shouldRequestAccessTokenWith code: String) {
        tokenResult?(code)
        print(code)
        eventSink?(manager)
    }
}
