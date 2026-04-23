#!/usr/bin/env swift

import Foundation

// Inline the Reflow code for a standalone test.
// Mirror of Sources/ReflowClip/Reflow.swift.

enum Reflow {
    private static let boxChars: Set<Character> = [
        "│", "┃", "║", "╭", "╮", "╰", "╯", "┌", "┐", "└", "┘",
        "─", "━", "═", "╌", "╍", "╎", "╏", "├", "┤", "┬", "┴", "┼"
    ]

    static func looksLikeTuiBlock(_ text: String) -> Bool {
        for ch in text where boxChars.contains(ch) { return true }
        return false
    }

    static func apply(_ text: String) -> String {
        let rawLines = text.components(separatedBy: .newlines)
        var processed = rawLines.map { stripBorders(from: $0) }.map { trimTrailing($0) }
        while let first = processed.first, first.isEmpty { processed.removeFirst() }
        while let last = processed.last, last.isEmpty { processed.removeLast() }
        if processed.isEmpty { return text }
        let indent = commonLeadingSpaces(processed)
        if indent > 0 {
            processed = processed.map { $0.count >= indent ? String($0.dropFirst(indent)) : $0 }
        }
        return joinReflowed(processed)
    }

    private static func stripBorders(from line: String) -> String {
        let chars = Array(line)
        var i = 0
        while i < chars.count, chars[i].isWhitespace { i += 1 }
        while i < chars.count, boxChars.contains(chars[i]) { i += 1 }
        if i < chars.count, chars[i] == " " { i += 1 }
        var j = chars.count
        while j > i, chars[j - 1].isWhitespace { j -= 1 }
        while j > i, boxChars.contains(chars[j - 1]) { j -= 1 }
        if j > i, chars[j - 1] == " " { j -= 1 }
        var result = String(chars[i..<j])
        result.removeAll { boxChars.contains($0) }
        return result
    }

    private static func trimTrailing(_ s: String) -> String {
        var end = s.endIndex
        while end > s.startIndex {
            let prev = s.index(before: end)
            if s[prev].isWhitespace { end = prev } else { break }
        }
        return String(s[s.startIndex..<end])
    }

    private static func commonLeadingSpaces(_ lines: [String]) -> Int {
        var minCount = Int.max
        for line in lines where !line.isEmpty {
            var count = 0
            for ch in line { if ch == " " { count += 1 } else { break } }
            if count < minCount { minCount = count }
        }
        return minCount == Int.max ? 0 : minCount
    }

    private static func joinReflowed(_ lines: [String]) -> String {
        var output: [String] = []
        var buffer = ""
        for line in lines {
            if line.isEmpty {
                if !buffer.isEmpty { output.append(buffer); buffer = "" }
                output.append("")
                continue
            }
            if buffer.isEmpty { buffer = line; continue }
            buffer = joinTwo(buffer, line)
        }
        if !buffer.isEmpty { output.append(buffer) }
        return output.joined(separator: "\n")
    }

    private static func joinTwo(_ a: String, _ b: String) -> String {
        if a.hasSuffix("\\") {
            let trimmed = String(a.dropLast()).trimmingCharacters(in: .whitespaces)
            return trimmed + " " + b.trimmingLeading()
        }
        let opsEnd = ["&&", "||", "|", ",", ";", "(", "[", "{", "<", "=", "+", "-", "*", "/"]
        for op in opsEnd { if a.hasSuffix(op) { return a + " " + b.trimmingLeading() } }
        let opsStart = ["&&", "||", "|", ",", ";", ")", "]", "}", ">"]
        for op in opsStart { if b.hasPrefix(op) { return trimTrailing(a) + " " + b } }
        guard let lastChar = a.last, let firstChar = b.first else { return a + b }
        let isToken: (Character) -> Bool = { ch in
            ch.isLetter || ch.isNumber || ch == "_" || ch == "-" || ch == "." ||
            ch == "/" || ch == ":" || ch == "=" || ch == "~" || ch == "@" || ch == "?" || ch == "&"
        }
        if isToken(lastChar) && isToken(firstChar) { return a + b }
        return a + " " + b.trimmingLeading()
    }
}

private extension String {
    func trimmingLeading() -> String {
        var i = startIndex
        while i < endIndex, self[i].isWhitespace { i = index(after: i) }
        return String(self[i..<endIndex])
    }
}

// Tests

struct TestCase {
    let name: String
    let input: String
    let expected: String
}

let cases: [TestCase] = [
    TestCase(
        name: "Claude-style box with && operators",
        input: """
        ╭──────────────────────────────────────────────────────────╮
        │  rm -rf ~/Desktop/test-admin && mkdir ~/Desktop/test-ad  │
        │  min && cd ~/Desktop/test-admin && curl -L -o a.zip      │
        ╰──────────────────────────────────────────────────────────╯
        """,
        expected: "rm -rf ~/Desktop/test-admin && mkdir ~/Desktop/test-admin && cd ~/Desktop/test-admin && curl -L -o a.zip"
    ),
    TestCase(
        name: "Simple two-line wrap",
        input: """
        │ echo hello &&  │
        │ echo world     │
        """,
        expected: "echo hello && echo world"
    ),
    TestCase(
        name: "URL broken mid-path",
        input: """
        ╭─────────────────────────────────╮
        │ curl "https://example.com/very  │
        │ long/path/here" && echo done    │
        ╰─────────────────────────────────╯
        """,
        expected: "curl \"https://example.com/verylong/path/here\" && echo done"
    ),
    TestCase(
        name: "No box chars — returns looksLikeTuiBlock = false",
        input: "foo\nbar\nbaz",
        expected: ""
    ),
]

var failed = 0
for tc in cases {
    if tc.expected.isEmpty {
        let detected = Reflow.looksLikeTuiBlock(tc.input)
        if detected {
            print("FAIL [\(tc.name)]: expected no TUI detection, but looksLikeTuiBlock=true")
            failed += 1
        } else {
            print("PASS [\(tc.name)]")
        }
        continue
    }
    guard Reflow.looksLikeTuiBlock(tc.input) else {
        print("FAIL [\(tc.name)]: looksLikeTuiBlock returned false on input with box chars")
        failed += 1
        continue
    }
    let actual = Reflow.apply(tc.input)
    if actual == tc.expected {
        print("PASS [\(tc.name)]")
    } else {
        print("FAIL [\(tc.name)]")
        print("  expected: \(tc.expected)")
        print("  actual:   \(actual)")
        failed += 1
    }
}

if failed > 0 {
    print("\n\(failed) failure(s)")
    exit(1)
} else {
    print("\nAll \(cases.count) tests passed.")
}
