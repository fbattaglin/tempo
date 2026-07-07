import Foundation

struct TimeSignature: Identifiable, Hashable, Codable {
    let beatsPerBar: Int
    let beatUnit: Int

    var id: String { "\(beatsPerBar)/\(beatUnit)" }
    var label: String { "\(beatsPerBar)/\(beatUnit)" }

    static let twoFour = TimeSignature(beatsPerBar: 2, beatUnit: 4)
    static let threeFour = TimeSignature(beatsPerBar: 3, beatUnit: 4)
    static let fourFour = TimeSignature(beatsPerBar: 4, beatUnit: 4)
    static let fiveFour = TimeSignature(beatsPerBar: 5, beatUnit: 4)
    static let sixEight = TimeSignature(beatsPerBar: 6, beatUnit: 8)
    static let sevenEight = TimeSignature(beatsPerBar: 7, beatUnit: 8)
    static let nineEight = TimeSignature(beatsPerBar: 9, beatUnit: 8)
    static let twelveEight = TimeSignature(beatsPerBar: 12, beatUnit: 8)

    static let common: [TimeSignature] = [
        .twoFour, .threeFour, .fourFour, .fiveFour, .sixEight, .sevenEight, .nineEight, .twelveEight,
    ]

    static let `default` = TimeSignature.fourFour
}
