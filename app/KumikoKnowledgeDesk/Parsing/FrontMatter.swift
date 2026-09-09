import Foundation

struct FrontMatter: Hashable, Sendable {
    var fields: [String: String] = [:]
    var lists: [String: [String]] = [:]
    var body: String = ""

    subscript(_ key: String) -> String? {
        guard let value = fields[key], !value.isEmpty else { return nil }
        return value
    }

    static func parse(_ text: String) -> FrontMatter {
        var result = FrontMatter()
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        guard let first = lines.first, first.trimmingCharacters(in: .whitespaces) == "---",
              let end = lines.indices.dropFirst().first(where: { lines[$0].trimmingCharacters(in: .whitespaces) == "---" }) else {
            result.body = text
            return result
        }
        result.body = lines[(end + 1)...].joined(separator: "\n")
        var currentListKey: String?
        for raw in lines[1..<end] {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            if line.hasPrefix("- "), let key = currentListKey {
                let item = clean(String(line.dropFirst(2)))
                if !item.isEmpty { result.lists[key, default: []].append(item) }
                result.fields[key] = result.lists[key]?.joined(separator: ", ") ?? ""
                continue
            }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let rawValue = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            currentListKey = nil
            if rawValue.isEmpty {
                currentListKey = key
                result.fields[key] = ""
            } else if rawValue.hasPrefix("["), rawValue.hasSuffix("]") {
                let items = rawValue.dropFirst().dropLast().split(separator: ",").map { clean(String($0)) }.filter { !$0.isEmpty }
                result.lists[key] = items
                result.fields[key] = items.joined(separator: ", ")
            } else {
                result.fields[key] = clean(rawValue)
            }
        }
        return result
    }

    private static func clean(_ value: String) -> String {
        var v = value.trimmingCharacters(in: .whitespaces)
        for quote in ["\"", "'"] where v.count >= 2 && v.hasPrefix(quote) && v.hasSuffix(quote) {
            return String(v.dropFirst().dropLast())
        }
        if let hash = v.range(of: " #") { v = String(v[..<hash.lowerBound]) }
        return v.trimmingCharacters(in: .whitespaces)
    }
}
