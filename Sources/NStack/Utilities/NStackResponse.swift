protocol NStackResponse: Decodable {
    associatedtype DataObject: Decodable
    associatedtype Metadata: Decodable

    var data: DataObject { get }
    var meta: Metadata { get }
}
