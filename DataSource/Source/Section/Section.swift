
import Foundation

public class Section<Object> {
    
    public var name: String?
    public var userInfo: [String: AnyObject]?
    
    public var objects: [Object] {
        fatalError("Not implemented")
    }
    
    public var numberOfObjects: Int {
        return objects.count
    }
    
    public init(name: String? = nil, userInfo: [String: AnyObject]? = nil) {
        self.name = name
        self.userInfo = userInfo
    }
}