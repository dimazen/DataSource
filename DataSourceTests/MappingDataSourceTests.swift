
import XCTest
import DataSource

class MappingDataSourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let dataSource = ArrayDataSource<Int>()
        let mappingDataSource = MappingDataSource(origin: dataSource) { value -> String in
            return String(value)
        }
        
        dataSource.append(1)
        
        mappingDataSource.sectionsCount
        
        dataSource.append(section: ArraySection(objects: [10]))
        dataSource.append(section: ArraySection(objects: [20]))
        
        print(mappingDataSource.numberOfObjects(inSection: 0))
        print(mappingDataSource.numberOfObjects(inSection: 1))
        print(mappingDataSource.numberOfObjects(inSection: 2))
    }
}
