import Foundation

struct AddAiPicsResponseBody : Decodable {
    let id: Int
    let signedRequests: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case signedRequests = "signed_requests"
    }

}
