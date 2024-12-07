import Foundation
import AndroidTVRemoteControl

public class AndroidTVManager: BaseTvManager {
    private let pairingManager: PairingManager
    private let remoteManager: RemoteManager
    
    public var delegate: BaseTVManagerDelegate?
    
    init() {
        let cryptoManager = CryptoManager()
        cryptoManager.clientPublicCertificate = {
            guard let url = Bundle.main.url(forResource: "cert", withExtension: "der") else {
                return .Error(.loadCertFromURLError(AndroidTVManagerError.certNotFound))
            }
            return CertManager().getSecKey(url)
        }
        
        let tlsManager = TLSManager {
            guard let url = Bundle.main.url(forResource: "cert", withExtension: "p12") else {
                return .Error(.loadCertFromURLError(AndroidTVManagerError.certNotFound))
            }
            return CertManager().cert(url, "")
        }
        
        tlsManager.secTrustClosure = { secTrust in
            cryptoManager.serverPublicCertificate = {
                if #available(iOS 14.0, *) {
                    guard let key = SecTrustCopyKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                } else {
                    guard let key = SecTrustCopyPublicKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                }
            }
        }
        
        pairingManager = PairingManager(tlsManager, cryptoManager, DefaultLogger())
        remoteManager = RemoteManager(tlsManager, CommandNetwork.DeviceInfo("client", "iPhone", appVersion, appName, buildVersion), DefaultLogger())
    }
    
    public func connect(host: String) {
        remoteManager.stateChanged = { [weak self] remoteState in
            guard let self = self else { return }
            print("remoteManager remoteState \(remoteState.toString())")
            if case .connected = remoteState {
                delegate?.deviceConnected()
            } else if case .error(.connectionWaitingError) = remoteState {
                self.pairing(host: host)
                delegate?.deviceWatingForAccept()
            } else if case .error = remoteState {
                delegate?.deviceConnectError()
            }
        }
        remoteManager.connect(host)
    }
    
    private func pairing(host: String) {
        pairingManager.stateChanged = { [weak self] pairingState in
            guard let self = self else { return }
            print("pairingManager pairingState \(pairingState.toString())")
            if case .successPaired = pairingState {
                self.remoteManager.connect(host)
            } else if case .error = pairingState {
                delegate?.deviceConnectError()
            }
        }
        pairingManager.connect(host, "client", "iPhone")
    }
    
    public func verifyCode(code: String) {
        pairingManager.sendSecret(code)
    }

    public func sendCommand(data: Any) {
        if let command = data as? TvCommand {
            if let key = command.convertToAndroidCommand() {
                remoteManager.send(KeyPress(key))
            }
        }
    }
    
    public func openApp(data: Any) {
        if let app = data as? TvApp {
            self.remoteManager.send(DeepLink(app.androidTvDeepLink))
        }
    }
    
    public func disconnect() {
        remoteManager.disconnect()
    }
}

public enum AndroidTVManagerError: Error {
    case certNotFound
}

public extension RemoteManager.RemoteState {
    func toString() -> String {
        switch self {
        case .idle:
            return "idle"
        case .connectionSetUp:
            return "connection Set Up"
        case .connectionPrepairing:
            return "connection Prepairing"
        case .connected:
            return "connected"
        case .fisrtConfigMessageReceived(let info):
            return "fisrt Config Message Received: vendor: \(info.vendor) model: \(info.model)"
        case .firstConfigSent:
            return "first Config Sent"
        case .secondConfigSent:
            return "second Config Sent"
        case .paired(let runningApp):
            return "Paired! Current runned app " + (runningApp ?? "")
        case .error(let error):
            return "Error: " + error.toString()
        }
    }
}

public extension PairingManager.PairingState {
    func toString() -> String {
        switch self {
        case .idle:
            return "idle"
        case .extractTLSparams:
            return "Extract TLS params"
        case .connectionSetUp:
            return "Connection Set Up"
        case .connectionPrepairing:
            return "Connection Prepairing"
        case .connected:
            return "Connected"
        case .pairingRequestSent:
            return "Pairing Request Sent"
        case .pairingResponseSuccess:
            return "Pairing Response Success"
        case .optionRequestSent:
            return "Option Request Sent"
        case .optionResponseSuccess:
            return "Option Response Success"
        case .confirmationRequestSent:
            return "Confirmation Request Sent"
        case .confirmationResponseSuccess:
            return "Confirmation Response Success"
        case .waitingCode:
            return "Waiting Code"
        case .secretSent:
            return "Secret Sent"
        case .successPaired:
            return "Success Paired"
        case .error(let error):
            return "Error: " + error.toString()
        }
    }
}

extension AndroidTVRemoteControlError {
    func toString() -> String {
        switch self {
        case .unexpectedCertData:
            return "unexpected Cert Data"
        case .extractCFTypeRefError:
            return "extract CFTypeRef Error"
        case .secIdentityCreateError:
            return "sec Identity Create Error"
        case .toLongNames(let description):
            return "to Long Names" + description
        case .connectionCanceled:
            return "connection Canceled"
        case .pairingNotSuccess:
            return "pairing Not Success"
        case .optionNotSuccess:
            return "option Not Success"
        case .configurationNotSuccess:
            return "configuration Not Success"
        case .secretNotSuccess:
            return "secret Not Success"
        case .connectionWaitingError(let error):
            return "connection Waiting Error: " + error.localizedDescription
        case .connectionFailed:
            return "connection Failed"
        case .receiveDataError:
            return "receive Data Error"
        case .sendDataError:
            return "send Data Error"
        case .invalidCode(let description):
            return "invalid Code " + description
        case .wrongCode:
            return "wrong Code"
        case .noSecAttributes:
            return "no SecAttributes"
        case .notRSAKey:
            return "not RSA Key"
        case .notPublicKey:
            return "not Public Key"
        case .noKeySizeAttribute:
            return "no Key Size Attribute"
        case .noValueData:
            return "no Value Data"
        case .invalidCertData:
            return "invalid Cert Data"
        case .createCertFromDataError:
            return "create Cert From Data Error"
        case .noClientPublicCertificate:
            return "no Client Public Certificate"
        case .noServerPublicCertificate:
            return "no Server Public Certificate"
        case .secTrustCopyKeyError:
            return "sec Trust Copy Key Error"
        case .loadCertFromURLError:
            return "load Cert From URL Error"
        case .secPKCS12ImportNotSuccess:
            return "secPKCS12Import Not Success"
        case .createTrustObjectError:
            return "create Trust Object Error"
        case .secTrustCreateWithCertificatesNotSuccess:
            return "secTrust Create With Certificates Not Success"
        }
    }
}
extension TvCommand {
    func convertToAndroidCommand() -> AndroidTVRemoteControl.Key? {
        switch self {
        case .KEY_MENU:
            return .KEYCODE_MENU
        case .KEY_UP:
            return .KEYCODE_DPAD_UP
        case .KEY_DOWN:
            return .KEYCODE_DPAD_DOWN
        case .KEY_LEFT:
            return .KEYCODE_DPAD_LEFT
        case .KEY_RIGHT:
            return .KEYCODE_DPAD_RIGHT
        case .KEY_PANNEL_ENTER:
            return .KEYCODE_ENTER
        case .KEY_BACK_MHP:
            return .KEYCODE_BACK
        case .KEY_HOME:
            return .KEYCODE_HOME
        case .KEY_VOLUP:
            return .KEYCODE_VOLUME_UP
        case .KEY_VOLDOWN:
            return .KEYCODE_VOLUME_DOWN
        case .KEY_MUTE:
            return .KEYCODE_MUTE
        case .KEY_POWER:
            return .KEYCODE_POWER
        case .KEY_PLAY:
            return .KEYCODE_MEDIA_PLAY_PAUSE
        case .KEY_PAUSE:
            return .KEYCODE_MEDIA_PLAY_PAUSE
        case .KEY_STOP:
            return .KEYCODE_MEDIA_STOP
        case .KEY_REWIND:
            return .KEYCODE_MEDIA_REWIND
        case .KEY_INFO:
            return .KEYCODE_INFO
        case .KEY_GUIDE:
            return .KEYCODE_GUIDE
        case .KEY_RED:
            return .KEYCODE_PROG_RED
        case .KEY_GREEN:
            return .KEYCODE_PROG_GREEN
        case .KEY_YELLOW:
            return .KEYCODE_PROG_YELLOW
        case .KEY_CYAN:
            return .KEYCODE_PROG_BLUE
        case .KEY_CHUP:
            return .KEYCODE_CHANNEL_UP
        case .KEY_CHDOWN:
            return .KEYCODE_CHANNEL_DOWN
        case .KEY_0:
            return .KEYCODE_0
        case .KEY_1:
            return .KEYCODE_1
        case .KEY_2:
            return .KEYCODE_2
        case .KEY_3:
            return .KEYCODE_3
        case .KEY_4:
            return .KEYCODE_4
        case .KEY_5:
            return .KEYCODE_5
        case .KEY_6:
            return .KEYCODE_6
        case .KEY_7:
            return .KEYCODE_7
        case .KEY_8:
            return .KEYCODE_8
        case .KEY_9:
            return .KEYCODE_9
        case .KEY_FF:
            return .KEYCODE_MEDIA_SKIP_FORWARD
        case .KEY_NEXT:
            return .KEYCODE_MEDIA_NEXT
        case .KEY_PREV:
            return .KEYCODE_MEDIA_PREVIOUS
        case .KEY_MIC:
            return .KEYCODE_ASSIST
        case .KEY_TV:
            return .KEYCODE_TV
        default:
            return nil
        }
    }
}
