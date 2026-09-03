import Foundation

struct Station: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let operatorName: String
    let note: String
    let url: URL

    var displayName: String { "\(operatorName) \(name)" }

    static let all: [Station] = [
        Station(
            name: "24/7",
            operatorName: "Lofi",
            note: "Round-the-clock lofi hiphop beats from lofi247.com.",
            url: URL(string: "https://usa9.fastcast4u.com/proxy/jamz?mp=/1")!
        ),
        Station(
            name: "Fluid",
            operatorName: "SomaFM",
            note: "Instrumental hiphop, future soul and liquid trap.",
            url: URL(string: "https://ice1.somafm.com/fluid-128-mp3")!
        ),
        Station(
            name: "Groove Salad Classic",
            operatorName: "SomaFM",
            note: "The original chilled plate of ambient beats and grooves.",
            url: URL(string: "https://ice2.somafm.com/gsclassic-128-mp3")!
        ),
        Station(
            name: "Groove Salad",
            operatorName: "SomaFM",
            note: "A nicely chilled plate of ambient beats and grooves.",
            url: URL(string: "https://ice4.somafm.com/groovesalad-128-mp3")!
        ),
        Station(
            name: "Groove Salad 2",
            operatorName: "SomaFM",
            note: "More chilled beats and grooves.",
            url: URL(string: "https://ice6.somafm.com/groovesalad2-128-mp3")!
        ),
        Station(
            name: "cliqhop idm",
            operatorName: "SomaFM",
            note: "Blips and bleeps backed by beats.",
            url: URL(string: "https://ice1.somafm.com/cliqhop-128-mp3")!
        ),
    ]
}
