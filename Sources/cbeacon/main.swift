//
//  main.swift
//  cbeacon
//
//  Created by ohya on 2018/12/31.
//  Copyright © 2018年 ohya. All rights reserved.
//

import Foundation
import SPMUtility
import Basic

let COMMAND_NAME = "cbeacon"
let VERSION_CODE = "0.4.1"

let DEFAULT_DURATION: UInt16 = 5
let MEASURED_POWER: Int8 = -68

extension UInt16 {
    init?(number: String) {
        let (radix, offset) = { (s) -> (Int, Int) in
            switch s.lowercased() {
            case _ where s.hasPrefix("0x"):
                return (16, 2)
            case _ where s.hasPrefix("0b"):
                return (2, 2)
            case _ where s.hasPrefix("0"):
                return (8, 0) // offset 0 (not 1) for ZERO
            default:
                return (10, 0)
            }
        }(number)

        guard number.count > offset else { return nil }
        let pos = number.index(number.startIndex, offsetBy: offset)
        self.init(number[pos...], radix: radix)
    }
}

struct CustomError: LocalizedError {
    let message: String
    init(_ message: String) {
        self.message = message
    }
    public var errorDescription: String? {
        return message
    }
}

func getArgs() -> (uuid: UUID, major: UInt16, minor: UInt16, time: UInt16) {
    do {
        // Create a parser
        let parser = ArgumentParser(
                commandName: "",
                usage: """

                \(COMMAND_NAME) [--time duration] <uuid> <major> <minor>
                \(COMMAND_NAME) --version
                """,
                overview: """

                This command line tool is for transmit iBeacon advertisements.
                iBeacon technology uses Bluetooth Low Energy (BLE).
                """
            )

        // Argument: uuid
        let uuidArg = parser.add(
                positional: "uuid",
                kind: String.self,
                usage: "Proximity UUID")

        // Argument: major
        let majorArg = parser.add(
                positional: "major",
                kind: String.self,
                usage: "Major (0-65535)")

        // Argument: minor
        let minorArg = parser.add(
                positional: "minor",
                kind: String.self,
                usage: "Minor (0-65535)")

        // Option: time
        let timeOpt = parser.add(
                option: "--time",
                shortName: "-t",
                kind: Int.self,
                usage: "Duration time for transmission in seconds. 5 seconds default.")

        // Option: version
        let versionOpt = parser.add(
                option: "--version",
                shortName: "-v",
                kind: Bool.self,
                usage: "Print version")

        // Prepare the arguments
        let arguments = Array(CommandLine.arguments.dropFirst())

        // Check if arguments are given
        if arguments.count == 0 {
            parser.printUsage(on: stdoutStream)
            exit(EXIT_FAILURE)
        }

        // Check version option
        // NOTE: Other arguments must be ignored if this option is specified
        if arguments.count == 1 {
            if arguments[0] == "--version" || arguments[0] == "-v" {
                print(COMMAND_NAME + ": version " + VERSION_CODE);
                exit(EXIT_SUCCESS)
            }
        }

        // Parse all arguments
        let result = try parser.parse(arguments)

        guard let uuidRaw  = result.get(uuidArg),
              let majorRaw = result.get(majorArg),
              let minorRaw = result.get(minorArg) else {
            print("Fatal Error: argument parser")
            exit(EXIT_FAILURE)
        }

        let invalidValue = { (arg, text) -> ArgumentParserError in
            return ArgumentParserError.invalidValue(argument: arg, error: ArgumentConversionError.custom(text))
        }

        // Get an argument: uuid
        guard let uuid = UUID(uuidString: uuidRaw) else {
            throw invalidValue("uuid", "Invalid UUID")
        }

        // Get an argument: major
        guard let major = UInt16(number: majorRaw) else {
            throw invalidValue("major", "Invalid Major")
        }

        // Get an argument: minor
        guard let minor = UInt16(number: minorRaw) else {
            throw invalidValue("minor", "Invalid Minor")
        }

        // Get an option: time
        let time = try { () -> UInt16 in
            guard let val = result.get(timeOpt) else {
                return DEFAULT_DURATION
            }
            guard UInt16.min <= val && val <= UInt16.max else {
                throw invalidValue("time", "Out of range")
            }
            return UInt16(val)
        }()

        // Get an option: version, but error
        if let _ = result.get(versionOpt) {
            throw CustomError("`--version' can not be used with other arguments")
        }

        // Done
        return (uuid, major, minor, time)

    } catch let error as ArgumentParserError {
        print(error.description)
    } catch {
        print(error.localizedDescription)
    }
    exit(EXIT_FAILURE)
}

func main() {
    guard #available(macOS 10.12, *) else {
        fatalError("This program requires macOS 10.12 or greater.")
    }

    // Get arguments
    let args = getArgs()
    
    // Create a data to transmit
    let beacon = BeaconData(uuid: args.uuid, major: args.major, minor: args.minor, measuredPower: MEASURED_POWER)
    
    // Create a controller
    let controller = BeaconController(beacon: beacon, duration: args.time)

    // Execute the controller
    controller.exec()
    
    exit(EXIT_SUCCESS)
}

main()
