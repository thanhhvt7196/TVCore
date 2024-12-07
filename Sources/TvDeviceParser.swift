import Foundation

class TvDeviceParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentValue = ""
    
    private var device: TvDeviceInfoModel?
    private var icons: [TvDeviceIconModel] = []
    private var services: [TvDeviceServiceModel] = []
    
    private var currentIcon: TvDeviceIconModel?
    private var currentService: TvDeviceServiceModel?
    private var currentData: [String: String] = [:]
    
    func parse(xml: String) -> TvDeviceInfoModel? {
        guard let data = xml.data(using: .utf8) else { return nil }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return device
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentValue = ""
        
        if elementName == "icon" {
            currentIcon = TvDeviceIconModel(mimetype: "", width: 0, height: 0, depth: 0, url: "")
        }
        
        if elementName == "service" {
            currentService = TvDeviceServiceModel(serviceType: "", serviceId: "", controlURL: "", eventSubURL: "", scpdURL: "")
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // Parse device properties
        if elementName == "deviceType" { currentData["deviceType"] = currentValue }
        if elementName == "pnpx:X_compatibleId" { currentData["compatibleId"] = currentValue }
        if elementName == "df:X_deviceCategory" { currentData["deviceCategory"] = currentValue }
        if elementName == "dlna:X_DLNADOC" { currentData["dlnaDoc"] = currentValue }
        if elementName == "friendlyName" { currentData["friendlyName"] = currentValue }
        if elementName == "manufacturer" { currentData["manufacturer"] = currentValue }
        if elementName == "manufacturerURL" { currentData["manufacturerURL"] = currentValue }
        if elementName == "modelDescription" { currentData["modelDescription"] = currentValue }
        if elementName == "modelName" { currentData["modelName"] = currentValue }
        if elementName == "modelNumber" { currentData["modelNumber"] = currentValue }
        if elementName == "modelURL" { currentData["modelURL"] = currentValue }
        if elementName == "serialNumber" { currentData["serialNumber"] = currentValue }
        if elementName == "UDN" { currentData["udn"] = currentValue }
        if elementName == "sec:ProductCap" { currentData["productCap"] = currentValue }
        if elementName == "pnpx:X_hardwareId" { currentData["hardwareId"] = currentValue }
        
        // Parse icons
        if currentIcon != nil {
            if elementName == "mimetype" { currentIcon?.mimetype = currentValue }
            if elementName == "width" { currentIcon?.width = Int(currentValue) ?? 0 }
            if elementName == "height" { currentIcon?.height = Int(currentValue) ?? 0 }
            if elementName == "depth" { currentIcon?.depth = Int(currentValue) ?? 0 }
            if elementName == "url" { currentIcon?.url = currentValue }
        }
        if elementName == "icon" {
            if let icon = currentIcon {
                icons.append(icon)
            }
            currentIcon = nil
        }
        
        // Parse services
        if currentService != nil {
            if elementName == "serviceType" { currentService?.serviceType = currentValue }
            if elementName == "serviceId" { currentService?.serviceId = currentValue }
            if elementName == "controlURL" { currentService?.controlURL = currentValue }
            if elementName == "eventSubURL" { currentService?.eventSubURL = currentValue }
            if elementName == "SCPDURL" { currentService?.scpdURL = currentValue }
        }
        if elementName == "service" {
            if let service = currentService {
                services.append(service)
            }
            currentService = nil
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        device = TvDeviceInfoModel(
            deviceType: currentData["deviceType"] ?? "",
            friendlyName: currentData["friendlyName"] ?? "",
            manufacturer: currentData["manufacturer"] ?? "",
            manufacturerURL: currentData["manufacturerURL"] ?? "",
            modelDescription: currentData["modelDescription"] ?? "",
            modelName: currentData["modelName"] ?? "",
            modelNumber: currentData["modelNumber"] ?? "",
            modelURL: currentData["modelURL"] ?? "",
            serialNumber: currentData["serialNumber"] ?? "",
            udn: currentData["udn"] ?? "",
            deviceID: currentData["deviceID"] ?? "",
            productCap: currentData["productCap"] ?? "",
            serviceList: services,
            icon: icons
        )
    }
}
