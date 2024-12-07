import Foundation

let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main
    .object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Remote Tv Easy"
let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
let buildVersion = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "20241128"

class TvUtils {
    func parseResponseSSDP(response: String) -> TvSSDPModel {
        let lines = response.components(separatedBy: "\r\n")
        var model = TvSSDPModel()
        for line in lines {
            if line.starts(with: "LOCATION:") {
                model.location = URL(string: line.replacingOccurrences(of: "LOCATION: ", with: ""))
            } else if line.starts(with: "SERVER:") {
                model.server = line.replacingOccurrences(of: "SERVER: ", with: "")
            } else if line.starts(with: "ST:") {
                model.st = line.replacingOccurrences(of: "ST: ", with: "")
            } else if line.starts(with: "USN:") {
                model.usn = line.replacingOccurrences(of: "USN: ", with: "")
            }
        }
        return model
    }
}
