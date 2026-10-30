import Foundation
import SwiftData

@MainActor
class CSVManager {
    static func generateCSV(entries: [ConsumptionEntry]) -> URL? {
        // Includes Entry ID to prevent duplicate imports, but relies on Item Name for item matching
        var csvText = "Entry ID,Timestamp,Time Included,Item,Category,Quantity,Total Price,Note\n"
        
        for entry in entries {
            let entryId = entry.id.uuidString
            let timestamp = String(format: "%.3f", entry.timestamp.timeIntervalSince1970)
            let hasTime = entry.hasTime ? "true" : "false"
            
            let item = escapeCSV(entry.consumable?.name ?? "Unknown")
            let category = escapeCSV(entry.consumable?.category.title ?? "Unknown")
            let quantity = String(entry.quantity)
            
            // Format cents into decimal string (e.g., 250 -> 2.50) using English POSIX locale for reliable CSV formatting
            let price = entry.unitPriceCents != nil ? Money.editableAmount(entry.unitPriceCents!, locale: Locale(identifier: "en_US_POSIX")) : ""
            let note = escapeCSV(entry.note)
            
            csvText += "\(entryId),\(timestamp),\(hasTime),\(item),\(category),\(quantity),\(price),\(note)\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("FixesExport.csv")
        do {
            try csvText.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to create CSV: \(error)")
            return nil
        }
    }
    
    private static func escapeCSV(_ string: String) -> String {
        let needsQuotes = string.contains(",") || string.contains("\"") || string.contains("\n")
        if needsQuotes {
            let escapedQuotes = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedQuotes)\""
        }
        return string
    }
    
    static func importCSV(url: URL, modelContext: ModelContext, existingItems: [Consumable], existingEntries: [ConsumptionEntry]) throws {
        let data = try String(contentsOf: url, encoding: .utf8)
        var rows = parseCSV(data)
        guard !rows.isEmpty else { return }
        
        // Check for headers and determine column mapping
        var hasHeaders = false
        if let first = rows.first?.first?.lowercased(), first.contains("id") || first.contains("timestamp") || first.contains("date") {
            hasHeaders = true
        }
        
        // Define indices (adapts if importing an older CSV without Entry IDs)
        let hasIDs = hasHeaders && rows.first![0].lowercased().contains("entry id")
        
        let entryIdIdx = hasIDs ? 0 : -1
        let timeIdx = hasIDs ? 1 : 0
        let hasTimeIdx = hasIDs ? 2 : 1
        let itemIdx = hasIDs ? 3 : 2
        let catIdx = hasIDs ? 4 : 3
        let qtyIdx = hasIDs ? 5 : 4
        let priceIdx = hasIDs ? 6 : 5
        let noteIdx = hasIDs ? 7 : 6
        
        if hasHeaders { rows.removeFirst() }
        
        var localItems = existingItems
        var existingEntryIDs = Set(existingEntries.map(\.id))
        
        for row in rows {
            guard row.count > noteIdx else { continue }
            
            let entryIDStr = entryIdIdx >= 0 ? row[entryIdIdx].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let timestampStr = row[timeIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let hasTimeStr = row[hasTimeIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let itemName = row[itemIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let categoryName = row[catIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let quantityStr = row[qtyIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let priceStr = row[priceIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            let note = row[noteIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Generate or parse Entry ID
            let entryUUID = UUID(uuidString: entryIDStr) ?? UUID()
            
            // Skip if this exact entry ID is already in the database
            if existingEntryIDs.contains(entryUUID) { continue }
            
            let timestamp: Date
            if let timeInterval = TimeInterval(timestampStr) {
                timestamp = Date(timeIntervalSince1970: timeInterval)
            } else if let isoDate = try? Date(timestampStr, strategy: .iso8601) {
                timestamp = isoDate
            } else {
                continue // Unrecognized time format
            }
            
            let hasTime = (hasTimeStr.lowercased() == "true")
            let quantity = Int(quantityStr) ?? 1
            
            // Parse decimal string back into cents using your utility
            let priceCents = priceStr.isEmpty ? nil : Money.cents(from: priceStr)
            
            // Find existing consumable by Name, or create a new one
            let item: Consumable
            if let existing = localItems.first(where: { $0.name.lowercased() == itemName.lowercased() }) {
                item = existing
            } else {
                let category = ConsumableCategory.allCases.first(where: { $0.title.lowercased() == categoryName.lowercased() }) ?? .other
                let newItem = Consumable(name: itemName, category: category, unitPriceCents: priceCents)
                modelContext.insert(newItem)
                localItems.append(newItem)
                item = newItem
            }
            
            let entry = ConsumptionEntry(
                id: entryUUID,
                consumable: item,
                quantity: quantity,
                timestamp: timestamp,
                hasTime: hasTime,
                unitPriceCents: priceCents,
                note: note
            )
            modelContext.insert(entry)
            existingEntryIDs.insert(entryUUID) // Track locally to prevent dupes in same CSV
        }
        try modelContext.save()
    }
    
    private static func parseCSV(_ string: String) -> [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        let characters = Array(string)
        var i = 0
        while i < characters.count {
            let char = characters[i]
            if char == "\"" {
                if inQuotes && i + 1 < characters.count && characters[i + 1] == "\"" {
                    currentField.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if (char == "\n" || char == "\r") && !inQuotes {
                if char == "\r" && i + 1 < characters.count && characters[i + 1] == "\n" { i += 1 }
                currentRow.append(currentField)
                result.append(currentRow)
                currentRow = []
                currentField = ""
            } else {
                currentField.append(char)
            }
            i += 1
        }
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            result.append(currentRow)
        }
        return result
    }
}
