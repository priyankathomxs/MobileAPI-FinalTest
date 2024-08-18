struct Artwork: Codable
{
    let _id: String
    let artworkID: String?
    let title: String?
    let artist: String?
    let medium: String?
    let subject: [String]?
    let yearCreated: Int?
    let description: String?
    let dimensions: Int?
    let imageURL: String?
    let style: [String]?
    let currentLocation: String?
 
}
