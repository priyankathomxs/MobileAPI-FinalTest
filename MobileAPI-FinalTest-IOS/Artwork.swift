struct Movie: Codable
{
    let _id: String
    let movieID: String?
    let title: String
    let studio: String
    let genres: [String]?
    let directors: [String]?
    let writers: [String]?
    let actors: [String]?
    let year: Int?
    let length: Int?
    let shortDescription: String?
    let mpaRating: String?
    let criticsRating: Double?
}
