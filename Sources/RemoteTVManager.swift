import CocoaAsyncSocket
import Foundation
import Network
import Starscream

public protocol BaseTvManager {
    var delegate: BaseTVManagerDelegate? { get set }
    
    func connect(host: String)
    func disconnect()
    func verifyCode(code: String)
    func sendCommand(data: Any)
    func openApp(data: Any)
}

public protocol BaseTVManagerDelegate {
    func deviceConnected()
    func deviceConnectError()
    func deviceWatingForAccept()
    func deviceDisconnected()
}

public protocol RemoteTVManagerDelegate {
    func deviceFound(device: TvDeviceModel)
    func deviceWatingForAccept(device: TvDeviceModel, needSendCode: Bool)
    func deviceConnected(device: TvDeviceModel)
    func deviceConnectError(device: TvDeviceModel)
    func deviceDisonnected(device: TvDeviceModel)
}

public class RemoteTVManager: NSObject {
    public static let shared = RemoteTVManager()
    
    private var udpSocket: GCDAsyncUdpSocket?
    private let ssdpHost = "239.255.255.250"
    private let ssdpPort: UInt16 = 1900
    private let mSearchMessage = "M-SEARCH * HTTP/1.1\r\nSt: upnp:rootdevice\r\nHost: 239.255.255.250:1900\r\nMan: \"ssdp:discover\"\r\nMX: 1\r\n\r\n"
    
    var device: TvDeviceModel?
    private var tvManager: BaseTvManager?
    public var delegate: RemoteTVManagerDelegate?
    
    public func searchDevice() {
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .background))
        do {
            try udpSocket?.enableBroadcast(true)
            if let data = mSearchMessage.data(using: .utf8) {
                print("udpSocket send m-search")
                udpSocket?.send(data, toHost: ssdpHost, port: ssdpPort, withTimeout: 10, tag: 0)
            }
            try udpSocket?.beginReceiving()
        } catch {
            print("Error setting up UDP socket: \(error)")
        }
    }
    
    public func stopSearching() {
        udpSocket?.close()
        udpSocket = nil
    }
    
    public func connect(to device: TvDeviceModel) {
        self.device = device
        if device is TvSamsungModel {
            tvManager = SamsungTvManager()
        } else if device is TvAndroidModel {
            tvManager = AndroidTVManager()
        }
        tvManager?.delegate = self
        tvManager?.connect(host: device.host)
    }
    
    public func send(code: String) {
        tvManager?.verifyCode(code: code)
    }
    
    public func disconnect() {
        tvManager?.disconnect()
    }
    
    public func send(command: TvCommand) {
        if device is TvSamsungModel {
            guard let commandScript = device?.getScript(for: command) else { return }
            tvManager?.sendCommand(data: commandScript)
        } else if device is TvAndroidModel {
            tvManager?.sendCommand(data: command)
        }
    }
    
    public func open(app: TvApp) {
        tvManager?.openApp(data: app)
    }
}

extension RemoteTVManager: BaseTVManagerDelegate {
    public func deviceConnected() {
        guard let device = device else { return }
        delegate?.deviceConnected(device: device)
    }
    
    public func deviceConnectError() {
        guard let device = device else { return }
        delegate?.deviceConnectError(device: device)
    }
    
    public func deviceWatingForAccept() {
        guard let device = device else { return }
        delegate?.deviceWatingForAccept(device: device, needSendCode: device is TvAndroidModel)
    }
    
    public func deviceDisconnected() {
        guard let device = device else { return }
        delegate?.deviceDisonnected(device: device)
    }
}

public extension RemoteTVManager {
    private func getInfo(from device: TvSSDPModel) {
        guard let url = device.location else {
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("getInfo error \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("getInfo error \(String(describing: response))")
                return
            }
            guard let data = data, let xml = String(data: data, encoding: .utf8) else {
                return
            }
            if let device = TvDeviceParser().parse(xml: xml)?.convertToTvDevice(host: url.host) {
                self?.delegate?.deviceFound(device: device)
            }
        }
        task.resume()
    }
}

extension RemoteTVManager: GCDAsyncUdpSocketDelegate {
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let response = String(data: data, encoding: .utf8) {
            print("udpSocket didReceive data \(response)")
            getInfo(from: TvUtils().parseResponseSSDP(response: response))
        }
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("didSendDataWithTag \(tag)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: (any Error)?) {
        print("didNotSendDataWithTag \(tag) \(error?.localizedDescription ?? "")")
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: (any Error)?) {
        print("withError \(error?.localizedDescription ?? "")")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: (any Error)?) {
        print("didNotConnect \(error?.localizedDescription ?? "")")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("didConnectToAddress \(String(data: address, encoding: .utf8) ?? "")")
    }
}

public enum TvCommand: String {
    case KEY_MENU
    case KEY_UP
    case KEY_DOWN
    case KEY_LEFT
    case KEY_RIGHT
    case KEY_VOLUP
    case KEY_VOLDOWN
    case KEY_0
    case KEY_1
    case KEY_2
    case KEY_3
    case KEY_4
    case KEY_5
    case KEY_6
    case KEY_7
    case KEY_8
    case KEY_9
    case KEY_10
    case KEY_11
    case KEY_12
    case KEY_MUTE
    case KEY_CHDOWN
    case KEY_CHUP
    case KEY_PRECH
    case KEY_GREEN
    case KEY_YELLOW
    case KEY_CYAN
    case KEY_ADDDEL
    case KEY_SOURCE
    case KEY_INFO
    case KEY_PIP_ONOFF
    case KEY_PIP_SWAP
    case KEY_PLUS100
    case KEY_CAPTION
    case KEY_PMODE
    case KEY_TTX_MIX
    case KEY_TV
    case KEY_PICTURE_SIZE
    case KEY_AD
    case KEY_PIP_SIZE
    case KEY_MAGIC_CHANNEL
    case KEY_PIP_SCAN
    case KEY_PIP_CHUP
    case KEY_PIP_CHDOWN
    case KEY_DEVICE_CONNECT
    case KEY_HELP
    case KEY_ANTENA
    case KEY_CONVERGENCE
    case KEY_AUTO_PROGRAM
    case KEY_FACTORY
    case KEY_3SPEED
    case KEY_RSURF
    case KEY_ASPECT
    case KEY_TOPMENU
    case KEY_GAME
    case KEY_QUICK_REPLAY
    case KEY_STILL_PICTURE
    case KEY_DTV
    case KEY_FAVCH
    case KEY_REWIND
    case KEY_STOP
    case KEY_PLAY
    case KEY_FF
    case KEY_NEXT
    case KEY_PREV
    case KEY_REC
    case KEY_PAUSE
    case KEY_TOOLS
    case KEY_INSTANT_REPLAY
    case KEY_LINK
    case KEY_FF_
    case KEY_GUIDE
    case KEY_REWIND_
    case KEY_ANGLE
    case KEY_RESERVED1
    case KEY_ZOOM1
    case KEY_PROGRAM
    case KEY_BOOKMARK
    case KEY_DISC_MENU
    case KEY_PRINT
    case KEY_RETURN
    case KEY_SUB_TITLE
    case KEY_CLEAR
    case KEY_VCHIP
    case KEY_REPEAT
    case KEY_DOOR
    case KEY_OPEN
    case KEY_WHEEL_LEFT
    case KEY_POWER
    case KEY_SLEEP
    case KEY_DMA
    case KEY_TURBO
    case KEY_FM_RADIO
    case KEY_DVR_MENU
    case KEY_MTS
    case KEY_PCMODE
    case KEY_TTX_SUBFACE
    case KEY_CH_LIST
    case KEY_RED
    case KEY_DNIe
    case KEY_SRS
    case KEY_CONVERT_AUDIO_MAINSUB
    case KEY_MDC
    case KEY_SEFFECT
    case KEY_DVR
    case KEY_DTV_SIGNAL
    case KEY_LIVE
    case KEY_PERPECT_FOCUS
    case KEY_HOME
    case KEY_ESAVING
    case KEY_WHEEL_RIGHT
    case KEY_CONTENTS
    case KEY_VCR_MODE
    case KEY_CATV_MODE
    case KEY_DSS_MODE
    case KEY_TV_MODE
    case KEY_DVD_MODE
    case KEY_STB_MODE
    case KEY_CALLER_ID
    case KEY_SCALE
    case KEY_ZOOM_MOVE
    case KEY_CLOCK_DISPLAY
    case KEY_AV1
    case KEY_SVIDEO1
    case KEY_COMPONENT1
    case KEY_SETUP_CLOCK_TIMER
    case KEY_COMPONENT2
    case KEY_MAGIC_BRIGHT
    case KEY_DVI
    case KEY_HDMI
    case KEY_W_LINK
    case KEY_DTV_LINK
    case KEY_APP_LIST
    case KEY_BACK_MHP
    case KEY_ALT_MHP
    case KEY_DNSe
    case KEY_RSS
    case KEY_ENTERTAINMENT
    case KEY_ID_INPUT
    case KEY_ID_SETUP
    case KEY_ANYNET
    case KEY_POWEROFF
    case KEY_POWERON
    case KEY_ANYVIEW
    case KEY_MS
    case KEY_MORE
    case KEY_PANNEL_POWER
    case KEY_PANNEL_CHUP
    case KEY_PANNEL_CHDOWN
    case KEY_PANNEL_VOLUP
    case KEY_PANNEL_VOLDOW
    case KEY_PANNEL_ENTER
    case KEY_PANNEL_MENU
    case KEY_PANNEL_SOURCE
    case KEY_AV2
    case KEY_AV3
    case KEY_SVIDEO2
    case KEY_SVIDEO3
    case KEY_ZOOM2
    case KEY_PANORAMA
    case KEY_4_3
    case KEY_16_9
    case KEY_DYNAMIC
    case KEY_STANDARD
    case KEY_MOVIE1
    case KEY_CUSTOM
    case KEY_AUTO_ARC_RESET
    case KEY_AUTO_ARC_LNA_ON
    case KEY_AUTO_ARC_LNA_OFF
    case KEY_AUTO_ARC_ANYNET_MODE_OK
    case KEY_AUTO_ARC_ANYNET_AUTO_START
    case KEY_AUTO_FORMAT
    case KEY_DNET
    case KEY_HDMI1
    case KEY_AUTO_ARC_CAPTION_ON
    case KEY_AUTO_ARC_CAPTION_OFF
    case KEY_AUTO_ARC_PIP_DOUBLE
    case KEY_AUTO_ARC_PIP_LARGE
    case KEY_AUTO_ARC_PIP_SMALL
    case KEY_AUTO_ARC_PIP_WIDE
    case KEY_AUTO_ARC_PIP_LEFT_TOP
    case KEY_AUTO_ARC_PIP_RIGHT_TOP
    case KEY_AUTO_ARC_PIP_LEFT_BOTTOM
    case KEY_AUTO_ARC_PIP_RIGHT_BOTTOM
    case KEY_AUTO_ARC_PIP_CH_CHANGE
    case KEY_AUTO_ARC_AUTOCOLOR_SUCCESS
    case KEY_AUTO_ARC_AUTOCOLOR_FAIL
    case KEY_AUTO_ARC_C_FORCE_AGING
    case KEY_AUTO_ARC_USBJACK_INSPECT
    case KEY_AUTO_ARC_JACK_IDENT
    case KEY_NINE_SEPERATE
    case KEY_ZOOM_IN
    case KEY_ZOOM_OUT
    case KEY_MIC
    case KEY_HDMI2
    case KEY_HDMI3
    case KEY_AUTO_ARC_CAPTION_KOR
    case KEY_AUTO_ARC_CAPTION_ENG
    case KEY_AUTO_ARC_PIP_SOURCE_CHANGE
    case KEY_HDMI4
    case KEY_AUTO_ARC_ANTENNA_AIR
    case KEY_AUTO_ARC_ANTENNA_CABLE
    case KEY_AUTO_ARC_ANTENNA_SATELLITE
    case KEY_EXT1
    case KEY_EXT2
    case KEY_EXT3
    case KEY_EXT4
    case KEY_EXT5
    case KEY_EXT6
    case KEY_EXT7
    case KEY_EXT8
    case KEY_EXT9
    case KEY_EXT10
    case KEY_EXT11
    case KEY_EXT12
    case KEY_EXT13
    case KEY_EXT14
    case KEY_EXT15
    case KEY_EXT16
    case KEY_EXT17
    case KEY_EXT18
    case KEY_EXT19
    case KEY_EXT20
    case KEY_EXT21
    case KEY_EXT22
    case KEY_EXT23
    case KEY_EXT24
    case KEY_EXT25
    case KEY_EXT26
    case KEY_EXT27
    case KEY_EXT28
    case KEY_EXT29
    case KEY_EXT30
    case KEY_EXT31
    case KEY_EXT32
    case KEY_EXT33
    case KEY_EXT34
    case KEY_EXT35
    case KEY_EXT36
    case KEY_EXT37
    case KEY_EXT38
    case KEY_EXT39
    case KEY_EXT40
    case KEY_EXT41
}

public enum TvApp: String {
    case youtube = "YouTube"
    case spotify = "Spotify"
    case netflix = "Netflix"
    case ipla = "ipla"
    case playerPl = "Player.pl"
    case dsVideo = "DS video"
    case plex = "Plex"
    case internet = "Internet"
    case smartPack = "Smart Pack"
    case eManual = "e-Manual"
    case facebookWatch = "Facebook Watch"
    case hboGo = "HBO GO"
    case primeVideo = "Prime Video"
    case eurosportPlayer = "Eurosport Player"
    case googlePlayMovies = "Movies & TV Google Play"
    case onetVOD = "Onet VOD"
    case mcAfeeSecurity = "McAfee Security for TV"
    case filmboxLive = "Filmbox Live"
    case elevenSports = "Eleven Sports"
    case chili = "CHILI"
    
    var samsungAppID: String {
        switch self {
        case .youtube: return "111299001912"
        case .spotify: return "3201606009684"
        case .netflix: return "11101200001"
        case .ipla: return "3201507004202"
        case .playerPl: return "3201508004642"
        case .dsVideo: return "111399002250"
        case .plex: return "3201512006963"
        case .internet: return "org.tizen.browser"
        case .smartPack: return "3201704012124"
        case .eManual: return "20172100006"
        case .facebookWatch: return "11091000000"
        case .hboGo: return "3201706012478"
        case .primeVideo: return "3201512006785"
        case .eurosportPlayer: return "3201703012079"
        case .googlePlayMovies: return "3201601007250"
        case .onetVOD: return "3201607009918"
        case .mcAfeeSecurity: return "3201612011418"
        case .filmboxLive: return "141299000100"
        case .elevenSports: return "3201702011871"
        case .chili: return "3201505002690"
        }
    }
    
    var androidTvDeepLink: String {
        switch self {
        case .youtube:
            return "vnd.youtube://"
        case .spotify:
            return "spotify://"
        case .netflix:
            return "nflx://www.netflix.com"
        case .ipla:
            return "ipla://"
        case .playerPl:
            return "playerpl://"
        case .dsVideo:
            return "dsvideo://"
        case .plex:
            return "plex://"
        case .internet:
            return "https://www.google.com"
        case .smartPack:
            return "smartpack://"
        case .eManual:
            return "emanual://"
        case .facebookWatch:
            return "fb://watch"
        case .hboGo:
            return "hbogo://"
        case .primeVideo:
            return "primevideo://"
        case .eurosportPlayer:
            return "eurosportplayer://"
        case .googlePlayMovies:
            return "googleplaymovies://"
        case .onetVOD:
            return "onetvod://"
        case .mcAfeeSecurity:
            return "mcafee://"
        case .filmboxLive:
            return "filmboxlive://"
        case .elevenSports:
            return "elevensports://"
        case .chili:
            return "chili://"
        }
    }
}
