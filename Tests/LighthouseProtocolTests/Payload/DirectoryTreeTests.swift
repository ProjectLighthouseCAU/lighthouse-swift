import XCTest
import Foundation
import LighthouseProtocol

final class DirectoryTreeTests: XCTestCase {
    func testSerialization() {
        try XCTAssertEqual(encode(DirectoryTree()), "{}")
        try XCTAssertEqual(encode([:]), "{}")
        try XCTAssertEqual(encode(["a": .resource]), #"{"a":null}"#)
        try XCTAssertEqual(encode(["a": .resource]), #"{"a":null}"#)
        try XCTAssertEqual(encode(["b": ["a": .resource]]), #"{"b":{"a":null}}"#)

        assertRoundtrips([:])
        assertRoundtrips(["a": .resource])
        assertRoundtrips(["a": .resource, "b": .resource])
        assertRoundtrips(["a": ["b": .resource, "c": [:]], "b": .resource])
    }

    private func encode(_ value: DirectoryTree) throws -> String {
        String(data: try JSONEncoder().encode(value), encoding: .utf8)!
    }

    private func decode(_ json: String) throws -> DirectoryTree {
        try JSONDecoder().decode(DirectoryTree.self, from: json.data(using: .utf8)!)
    }

    private func assertRoundtrips(_ value: DirectoryTree, line: UInt = #line) {
        try XCTAssertEqual(decode(encode(value)), value, line: line)
    }
}
