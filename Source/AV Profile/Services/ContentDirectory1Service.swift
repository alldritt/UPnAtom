//
//  ContentDirectory1Service.swift
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import Fuzi

@objcMembers public class ContentDirectory1Service: AbstractUPnPService {
    public func getSearchCapabilities(_ success: @escaping (_ searchCapabilities: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSearchCapabilities", serviceURN: urn, arguments: nil)

        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task, responseObject) in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["SearchCaps"])
        }) { (task, error) in
failure(error as NSError)
        }
    }
    
    public func getSortCapabilities(_ success: @escaping (_ sortCapabilities: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSortCapabilities", serviceURN: urn, arguments: nil)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["SortCaps"])
            }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                failure(error as NSError)
        })
    }
    
    public func getSystemUpdateID(_ success: @escaping (_ systemUpdateID: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSystemUpdateID", serviceURN: urn, arguments: nil)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["Id"])
            }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                failure(error as NSError)
        })
    }
    
    public func browse(objectID: String, browseFlag: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, success: @escaping (_ result: [ContentDirectory1Object], _ numberReturned: Int, _ totalMatches: Int, _ updateID: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = [
            "ObjectID",objectID,
            "BrowseFlag",browseFlag,
            "Filter", filter,
            "StartingIndex",startingIndex,
            "RequestedCount",requestedCount,
            "SortCriteria",sortCriteria]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Browse", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: { () -> Void in
                let responseObject = responseObject as? [String: String]
                
                var result = [ContentDirectory1Object]()
                if let resultString = responseObject?["Result"],
                    let parserResult = ContentDirectoryBrowseResultParser().parse(browseResultData: resultString.data(using: String.Encoding.utf8)!).value {
                        result = parserResult
                }
                
                DispatchQueue.main.async(execute: { () -> Void in                    
                    success(result, Int(String(describing: responseObject?["NumberReturned"])) ?? 0, Int(String(describing: responseObject?["TotalMatches"])) ?? 0, responseObject?["UpdateID"])
                })
            })
            }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                failure(error as NSError)
        })
    }
    
    public func search(containerID: String, searchCriteria: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, success: @escaping (_ result: [ContentDirectory1Object], _ numberReturned: Int, _ totalMatches: Int, _ updateID: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = [
            "ContainerID",containerID,
            "SearchCriteria",searchCriteria,
            "Filter", filter,
            "StartingIndex",startingIndex,
            "RequestedCount",requestedCount,
            "SortCriteria",sortCriteria]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Search", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "Search" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: { () -> Void in
                        let responseObject = responseObject as? [String: String]
                        
                        var result = [ContentDirectory1Object]()
                        if let resultString = responseObject?["Result"],
                            let parserResult = ContentDirectoryBrowseResultParser().parse(browseResultData: resultString.data(using: String.Encoding.utf8)!).value {
                                result = parserResult
                        }
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            success(result, Int(String(describing: responseObject?["NumberReturned"])) ?? 0, Int(String(describing: responseObject?["TotalMatches"])) ?? 0, responseObject?["UpdateID"])
                        })
                    })
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func createObject(containerID: String, elements: String, success: @escaping (_ objectID: String?, _ result: [ContentDirectory1Object]) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = [
            "ContainerID",containerID,
            "Elements",elements]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "CreateObject", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "CreateObject" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: { () -> Void in
                        let responseObject = responseObject as? [String: String]
                        
                        var result = [ContentDirectory1Object]()
                        if let resultString = responseObject?["Result"],
                            let parserResult = ContentDirectoryBrowseResultParser().parse(browseResultData: resultString.data(using: String.Encoding.utf8)!).value {
                                result = parserResult
                        }
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            success(responseObject?["ObjectID"], result)
                        })
                    })
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func destroyObject(objectID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["ObjectID",objectID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "DestroyObject", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "DestroyObject" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    success()
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func updateObject(objectID: String, currentTagValue: String, newTagValue: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "ObjectID",objectID,
            "CurrentTagValue",currentTagValue,
            "NewTagValue",newTagValue]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "UpdateObject", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "UpdateObject" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    success()
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func importResource(sourceURI: String, destinationURI: String, success: @escaping (_ transferID: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "SourceURI",sourceURI,
            "DestinationURI",destinationURI]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ImportResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "ImportResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(responseObject?["TransferID"])
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func exportResource(sourceURI: String, destinationURI: String, success: @escaping (_ transferID: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "SourceURI",sourceURI,
            "DestinationURI",destinationURI]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ExportResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "ExportResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(responseObject?["TransferID"])
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func stopTransferResource(transferID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["TransferID",transferID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "StopTransferResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "StopTransferResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    success()
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func getTransferProgress(transferID: String, success: @escaping (_ transferStatus: String?, _ transferLength: String?, _ transferTotal: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["TransferID",transferID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetTransferProgress", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "GetTransferProgress" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(responseObject?["TransferStatus"], responseObject?["TransferLength"], responseObject?["TransferTotal"])
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func deleteResource(resourceURI: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["ResourceURI",resourceURI]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "DeleteResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "DeleteResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    success()
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
    
    public func createReference(containerID: String, objectID: String, success: @escaping (_ newID: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "ContainerID",containerID,
            "ObjectID",objectID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "CreateReference", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "CreateReference" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, headers: nil, progress: nil, success: { (task: URLSessionDataTask, responseObject: Any?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(responseObject?["NewID"])
                    }, failure: { (task: URLSessionDataTask?, error: Error) -> Void in
                        failure(error as NSError)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(String(describing: self.device?.friendlyName))") as NSError)
            }
        }
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isContentDirectory1Service() -> Bool {
        return self is ContentDirectory1Service
    }
}

/// overrides ExtendedPrintable protocol implementation
extension ContentDirectory1Service {
//    override public var className: String { return "\(type(of: self))" }
    override public var description: String {
        let properties = PropertyPrinter()
//        properties.add(super.className, property: super.description)
        return properties.description
    }
}

class ContentDirectoryBrowseResultParser: AbstractDOMXMLParser {
    fileprivate var _contentDirectoryObjects = [ContentDirectory1Object]()
    
    override func parse(document: Fuzi.XMLDocument) -> EmptyResult {
        let result: EmptyResult = .success
        document.definePrefix("didllite", forNamespace: "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/")
        for element in document.xpath("/didllite:DIDL-Lite/*") {
            switch element.firstChild(tag: "class")?.stringValue {
            case .some(let rawType) where rawType.range(of: "object.container.album.musicAlbum") != nil: // some servers use object.container and some use object.container.storageFolder
                if let contentDirectoryObject = ContentDirectory1AlbumContainer(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            case .some(let rawType) where rawType.range(of: "object.container.person.musicArtist") != nil: // some servers use object.container and some use object.container.storageFolder
                if let contentDirectoryObject = ContentDirectory1ArtistContainer(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            case .some(let rawType) where rawType.range(of: "object.container.genre.musicGenre") != nil: // some servers use object.container and some use object.container.storageFolder
                if let contentDirectoryObject = ContentDirectory1GenreContainer(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            case .some(let rawType) where rawType.range(of: "object.container") != nil: // some servers use object.container and some use object.container.storageFolder
                if let contentDirectoryObject = ContentDirectory1Container(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            case .some(let rawType) where rawType.range(of: "object.item.videoItem") != nil:
                if let contentDirectoryObject = ContentDirectory1VideoItem(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            case .some(let rawType) where rawType.range(of: "object.item.audioItem") != nil:
                if let contentDirectoryObject = ContentDirectory1AudioItem(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            default:
                if let contentDirectoryObject = ContentDirectory1Object(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                
                }
            }
        }
        
        return result
    }
    
    func parse(browseResultData: Data) -> Result<[ContentDirectory1Object]> {
        switch super.parse(data: browseResultData) {
        case .success:
            return .success(_contentDirectoryObjects)
        case .failure(let error):
            return .failure(error as NSError)
        }
    }
}
