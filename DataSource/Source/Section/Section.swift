
import Foundation

open class Section<Object> {
    
    open var name: String?
    open var userInfo: [String: AnyObject]?
    
    open var objects: [Object] {
        fatalError("Not implemented")
    }
    
    open var numberOfObjects: Int {
        return objects.count
    }
    
    open init(name: String? = nil, userInfo: [String: AnyObject]? = nil) {
        self.name = name
        self.userInfo = userInfo
        
    }
}
