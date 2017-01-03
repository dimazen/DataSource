
import Foundation



public enum ChangeType {
    
    case insert, delete, move, update
}

public struct SectionChange {

    var type: ChangeType
    var indexes: IndexSet
}

public struct ObjectChange {
    
    var type: ChangeType
    var source: IndexPath!
    var target: IndexPath!
    
    public init(type: ChangeType, source: IndexPath) {
        self.type = type
        self.source = source
    }
    
    public init(type: ChangeType, target: IndexPath) {
        self.type = type
        self.target = target
    }
    
    public init(type: ChangeType, source: IndexPath, target: IndexPath) {
        self.type = type
        self.source = source
        self.target = target
    }
}

public enum Event {

    case invalidate, reload, willBeginUpdate, didEndUpdate
    
    case sectionUpdate(SectionChange)
    case objectUpdate(ObjectChange)
}
