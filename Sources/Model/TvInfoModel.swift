public struct TvDeviceInfoModel {
    var deviceType: String
    var friendlyName: String
    var manufacturer: String
    var manufacturerURL: String
    var modelDescription: String
    var modelName: String
    var modelNumber: String
    var modelURL: String
    var serialNumber: String
    var udn: String
    var deviceID: String
    var productCap: String
    var serviceList: [TvDeviceServiceModel]
    var icon: [TvDeviceIconModel]
    
    func convertToTvDevice(host: String?) -> TvDeviceModel? {
        guard let host = host else { return nil }
        if [friendlyName, manufacturer, modelDescription].contains(where: { $0.lowercased().contains("samsung") }) {
            return TvSamsungModel(host: host, name: friendlyName)
        } else {
            return TvAndroidModel(host: host, name: friendlyName)
        }
    }
}

public struct TvDeviceServiceModel {
    var serviceType: String
    var serviceId: String
    var controlURL: String
    var eventSubURL: String
    var scpdURL: String
}

public struct TvDeviceIconModel {
    var mimetype: String
    var width: Int
    var height: Int
    var depth: Int
    var url: String
}
