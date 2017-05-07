import Foundation
import SwiftyJSON
import Darwin.C
struct System {
    var elw = 0
    var ww = 0
    var wwt = 0
    var tf = 0
    var aw = 0
}

var valuableSystems = [Int:System]()

func loadBodies() {
    guard let systemrows = try? String(contentsOfFile: "valuable-bodies.jsonl").components(separatedBy: "\n") else {
        exit(1)
    }

    var bodies = 0
    var elw = 0
    var ww = 0
    var tf = 0
    var aw = 0
    var systems = 0
    for systemline in systemrows {
        let systemjson = JSON(parseJSON: systemline)
        guard let systemid = systemjson["id"].int else {
            continue
        }
        let existingsystem = valuableSystems[systemid]
        if existingsystem != nil {
            systems += 1
        }

        var system = existingsystem ?? System()
        switch systemjson["type_name"] {
        case "Earth-like world":
            system.elw += 1
            elw += 1
        case "Water world":
            system.ww += 1
            ww += 1
            if systemjson["terraforming_state_id"] == 2 {
                system.wwt += 1
            }
        case "Ammonia world":
            system.aw += 1
            aw += 1
        default:
            if systemjson["terraforming_state_id"] == 2 {
                system.tf += 1
                tf += 1
            }
        }
        valuableSystems[systemid] = system
        bodies += 1
        if (bodies % 1000) == 0 {
            print("\rBodies: \(bodies), ELW: \(elw), WW: \(ww), AW: \(aw), TF: \(tf)                 ", terminator: "")
            fflush(stdout)
        }

    }
    print("\rparsed \(bodies) bodies in \(valuableSystems.count) systems.")
}

loadBodies()

FileManager.default.createFile(atPath: "system-coords.csv", contents: nil)
guard let handle = FileHandle(forUpdatingAtPath: "system-coords.csv") else {
    print("Failed to open output")
    exit(1)
}

handle.truncateFile(atOffset: 0)

var found = 0
if let aStreamReader = StreamReader(path: "systems.csv") {
    defer {
        aStreamReader.close()
    }
    while let rowline = aStreamReader.nextLine() {
        let row = rowline.components(separatedBy: ",")
        if (row.count < 8) {
            continue
        }
        guard let id = Int(row[0]), row[7] == "0" else {
            continue
        }


        found += 1
        if (found % 1000) == 0 {
            print("\r\(found)                  ", terminator: "")
            fflush(stdout)
        }

        guard let system = valuableSystems[id] else {
            continue;
        }
        let systemName = row[2].replacingOccurrences(of: "\"", with: "")
        let rowstring = "\(systemName)\t\(row[3])\t\(row[4])\t\(row[5])\t\(system.elw)\t\(system.ww)\t\(system.wwt)\t\(system.aw)\t\(system.tf)\n"
        if let rowdata = rowstring.data(using: .isoLatin1, allowLossyConversion: false) {
            handle.write(rowdata)
        }
    }
}

handle.closeFile()

exit(0)
