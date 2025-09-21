import Foundation

struct Comment: Decodable {
    let body: ADFBody?
}

struct ADFBody: Decodable {
    let content: [ADFNode]
}

struct ADFNode: Decodable {
    let text: String?
    let content: [ADFNode]?
}
