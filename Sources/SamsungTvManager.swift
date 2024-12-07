import Starscream
import Foundation

public class SamsungTvManager: BaseTvManager {
    var host: String = ""
    var socket: WebSocket?
    public var delegate: BaseTVManagerDelegate?
    
    public func connect(host: String) {
        self.host = host
        let appNameBase64 = appName.data(using: .utf8)?.base64EncodedString() ?? ""
        let request = URLRequest(url: URL(string: "wss://\(host):8002/api/v2/channels/samsung.remote.control?name=\(appNameBase64)")!)
        socket = WebSocket(request: request, certPinner: FoundationSecurity(allowSelfSigned: true))
        socket?.delegate = self
        socket?.connect()
    }
    
    public func verifyCode(code: String) {
        
    }
    
    public func disconnect() {
        socket?.disconnect()
        socket = nil
    }
    
    public func sendCommand(data: Any) {
        if let str = data as? String {
            socket?.write(string: str)
        }
    }
    
    public func openApp(data: Any) {
        guard let app = data as? TvApp, let url = URL(string: "http://\(host):8001/api/v2/applications/\(app.samsungAppID)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
        }
        task.resume()
    }
}

extension SamsungTvManager: WebSocketDelegate {
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let dictionary):
            delegate?.deviceWatingForAccept()
            print("didReceive Starscream.WebSocketEvent connected \(dictionary)")
        case .disconnected(let string, let uInt16):
            delegate?.deviceDisconnected()
            print("didReceive Starscream.WebSocketEvent disconnected \(string) \(uInt16)")
        case .text(let string):
            if string.contains("ms.channel.connect") {
                delegate?.deviceConnected()
            }
            print("didReceive Starscream.WebSocketEvent text \(string)")
        case .binary(let data):
            print("didReceive Starscream.WebSocketEvent text \(data)")
        case .pong(let data):
            print("didReceive Starscream.WebSocketEvent text \(String(describing: data))")
        case .ping(let data):
            print("didReceive Starscream.WebSocketEvent text \(String(describing: data))")
        case .error(let error):
            delegate?.deviceConnectError()
            print("didReceive Starscream.WebSocketEvent error \(error?.localizedDescription ?? "")")
        case .viabilityChanged(let bool):
            print("didReceive Starscream.WebSocketEvent viabilityChanged \(bool)")
        case .reconnectSuggested(let bool):
            print("didReceive Starscream.WebSocketEvent reconnectSuggested \(bool)")
        case .cancelled:
            delegate?.deviceConnectError()
            print("didReceive Starscream.WebSocketEvent cancelled")
        case .peerClosed:
            delegate?.deviceDisconnected()
            print("didReceive Starscream.WebSocketEvent peerClosed")
        }
    }
}
