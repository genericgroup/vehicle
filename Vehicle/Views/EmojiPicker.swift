import SwiftUI

struct EmojiItem: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
}

struct EmojiPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedEmoji: String
    @State private var searchText = ""
    @State private var localSelectedEmoji: String
    @State private var isProcessingSelection = false
    
    private let logger = AppLogger.shared
    
    init(selectedEmoji: Binding<String>) {
        self._selectedEmoji = selectedEmoji
        self._localSelectedEmoji = State(initialValue: selectedEmoji.wrappedValue)
        logger.debug("Initializing EmojiPicker with emoji: '\(selectedEmoji.wrappedValue)'", category: .userInterface)
    }
    
    // Color circles
    private let colorEmojis = [
        "⚪️", "⚫️", "🔴", "🔵", "🟢", "🟡", "🟣", "🟤", "🟠", "🔘"
    ].map { EmojiItem(emoji: $0) }
    
    // Numbers
    private let numberEmojis = [
        "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣"
    ].map { EmojiItem(emoji: $0) }
    
    // Circled Letters
    private let letterEmojis = [
        "Ⓐ", "Ⓑ", "Ⓒ", "Ⓓ", "Ⓔ", "Ⓕ", "Ⓖ", "Ⓗ", "Ⓘ", "Ⓙ", 
        "Ⓚ", "Ⓛ", "Ⓜ", "Ⓝ", "Ⓞ", "Ⓟ", "Ⓠ", "Ⓡ", "Ⓢ", "Ⓣ", 
        "Ⓤ", "Ⓥ", "Ⓦ", "Ⓧ", "Ⓨ", "Ⓩ"
    ].map { EmojiItem(emoji: $0) }
    
    // Basic Shapes
    private let shapeEmojis = [
        "⭐️", "❤️", "⚡️", "💫", "⭕️", "🔷", "🔶", "▪️", "🔺", "💠", "🔸", "🔹", "🔻"
    ].map { EmojiItem(emoji: $0) }
    
    // Weather & Nature
    private let weatherEmojis = [
        "☀️", "🌙", "⛅️", "❄️", "💧", "🔥", "🌈", "⚡️", "🌪️", "☔️"
    ].map { EmojiItem(emoji: $0) }
    
    // Common Symbols
    private let symbolEmojis = [
        "✅", "❌", "❗️", "❓", "⚠️", "💡", "🎯", "⚜️", "♾️", "💭", "💬", "🔔", "📢"
    ].map { EmojiItem(emoji: $0) }
    
    // Vehicle Related Symbols
    private let vehicleSymbolEmojis = [
        "🔑", "⛽️", "🔋", "💰", "📊", "📝", "🔧", "🛠️", "📅", "⚠️", 
        "💭", "📍", "🏁", "🎯", "💯", "📦", "🔔", "📱", "💳", "🔍"
    ].map { EmojiItem(emoji: $0) }
    
    // Flags
    private let flagEmojis = [
        "🏁", "🚩", "🎌", "🏳️", "⛳️"
    ].map { EmojiItem(emoji: $0) }
    
    // Time Related
    private let timeEmojis = [
        "⏰", "⌚️", "📅", "⌛️", "⏱️", "📆"
    ].map { EmojiItem(emoji: $0) }
    
    // Direction & Location
    private let directionEmojis = [
        "⬆️", "⬇️", "➡️", "⬅️", "↗️", "↘️", "↙️", "↖️", "📍", "🎯", "🧭"
    ].map { EmojiItem(emoji: $0) }
    
    // All transportation and vehicle related emoji categories
    private let categoryEmojis: [(String, [EmojiItem])] = [
        ("Ground Transportation", [
            "🚗", "🚙", "🚕", "🚌", "🚎", "🚓", "🚑", "🚒", "🚐", "🚚", "🚛",
            "🏎", "🚲", "🛵", "🏍", "🛺", "🦽", "🦼", "🛻"
        ].map { EmojiItem(emoji: $0) }),
        ("Recreational Vehicles", [
            "🚐", "🛻", "🏍", "🛵", "🚲", "🛹", "🛼", "🛷", "🛥", "⛵️", "🚤", "🏄‍♂️"
        ].map { EmojiItem(emoji: $0) }),
        ("Construction & Industrial", [
            "🚜", "🚛", "🏗", "🚧", "⚒️", "🛠", "⛏", "🔨", "🪛", "🔧", "🔩", "⚙️",
            "🦺", "⛓️", "🪜", "📏", "🔌", "🔋"
        ].map { EmojiItem(emoji: $0) }),
        ("Lawn & Garden", [
            "🌳", "🌲", "🌿", "🌱", "🌺", "🌸", "🪴", "🎋", "🎍", "🍂", "🌾",
            "⚡️", "💧", "🌡️", "🪣", "🧰", "🗜️", "🪚"
        ].map { EmojiItem(emoji: $0) }),
        ("Aviation", [
            "✈️", "🛩", "🚁", "🛸", "🚀", "🛫", "🛬", "💺", "🪂"
        ].map { EmojiItem(emoji: $0) }),
        ("Marine", [
            "⛵️", "🚢", "🛥", "⛴", "🛳", "🚤", "🛶", "🎣", "⚓️", "🏊‍♂️", "🌊"
        ].map { EmojiItem(emoji: $0) }),
        ("Farm & Agriculture", [
            "🚜", "🌾", "🌱", "🚛", "🏗", "🐎", "🐄", "🐖", "🐑", "🌽", 
            "🥕", "🥬", "🌻", "🏡"
        ].map { EmojiItem(emoji: $0) }),
        ("Service & Utility", [
            "🚨", "🚓", "🚑", "🚒", "🚐", "🚚", "⛽️", "🔌", "🔋", "⚡️",
            "🛠", "🧰", "🪛", "🔧", "🔨"
        ].map { EmojiItem(emoji: $0) }),
        ("Status & Warning", [
            "⚠️", "🚸", "🚫", "⛔️", "🚯", "🚳", "🚷", "🔰", "♨️", "💢",
            "❌", "✅", "⭕️", "❗️", "❓"
        ].map { EmojiItem(emoji: $0) })
    ]
    
    private var filteredEmojis: [(String, [EmojiItem])] {
        if searchText.isEmpty {
            return categoryEmojis
        }
        
        logger.debug("Filtering emojis with search text: '\(searchText)'", category: .userInterface)
        let filtered = categoryEmojis.compactMap { category, emojis in
            let filtered = emojis.filter { item in
                let emojiDescription = item.emoji.unicodeScalars.first?.properties.name?.lowercased() ?? ""
                return emojiDescription.contains(searchText.lowercased())
            }
            return filtered.isEmpty ? nil : (category, filtered)
        }
        logger.debug("Found \(filtered.count) categories with matching emojis", category: .userInterface)
        return filtered
    }
    
    private func selectEmoji(_ item: EmojiItem) {
        guard !isProcessingSelection else { return }
        isProcessingSelection = true
        
        logger.info("User selected emoji: \(item.emoji) (ID: \(item.id))", category: .userInterface)
        
        // Update local state first
        let previousEmoji = localSelectedEmoji
        localSelectedEmoji = item.emoji
        logger.debug("Changed local emoji from '\(previousEmoji)' to '\(item.emoji)'", category: .userInterface)
        
        // Update binding
        selectedEmoji = item.emoji
        logger.debug("Updated binding emoji to '\(item.emoji)'", category: .userInterface)
        
        // Save changes
        do {
            try modelContext.save()
            logger.debug("Saved emoji change to model context", category: .database)
            dismiss()
        } catch {
            logger.error("Failed to save emoji change: \(error.localizedDescription)", category: .database)
            isProcessingSelection = false
        }
    }
    
    private func emojiButton(for item: EmojiItem) -> some View {
        Button {
            withAnimation {
                selectEmoji(item)
            }
        } label: {
            Text(verbatim: item.emoji)
                .font(.title)
                .opacity(isProcessingSelection ? 0.5 : 1.0)
                .id(item.id)
        }
        .buttonStyle(.plain)
        .disabled(isProcessingSelection)
    }
    
    private func emojiGrid(emojis: [EmojiItem]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
            ForEach(emojis) { item in
                emojiButton(for: item)
            }
        }
        .padding(.vertical, 8)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        guard !isProcessingSelection else { return }
                        isProcessingSelection = true
                        
                        logger.info("User cleared emoji selection", category: .userInterface)
                        
                        // Update local state first
                        localSelectedEmoji = ""
                        logger.debug("Cleared local emoji selection", category: .userInterface)
                        
                        // Update binding
                        selectedEmoji = ""
                        logger.debug("Cleared binding emoji", category: .userInterface)
                        
                        // Save changes
                        do {
                            try modelContext.save()
                            logger.debug("Saved cleared emoji to model context", category: .database)
                            dismiss()
                        } catch {
                            logger.error("Failed to save cleared emoji: \(error.localizedDescription)", category: .database)
                            isProcessingSelection = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                            Text("None")
                                .foregroundStyle(.primary)
                        }
                    }
                    .disabled(isProcessingSelection)
                }
                
                Section("COLORS") {
                    emojiGrid(emojis: colorEmojis)
                }
                
                Section("NUMBERS") {
                    emojiGrid(emojis: numberEmojis)
                }
                
                Section("LETTERS") {
                    emojiGrid(emojis: letterEmojis)
                }
                
                Section("SHAPES") {
                    emojiGrid(emojis: shapeEmojis)
                }
                
                Section("VEHICLE SYMBOLS") {
                    emojiGrid(emojis: vehicleSymbolEmojis)
                }
                
                Section("FLAGS") {
                    emojiGrid(emojis: flagEmojis)
                }
                
                Section("WEATHER & NATURE") {
                    emojiGrid(emojis: weatherEmojis)
                }
                
                Section("SYMBOLS") {
                    emojiGrid(emojis: symbolEmojis)
                }
                
                Section("TIME") {
                    emojiGrid(emojis: timeEmojis)
                }
                
                Section("DIRECTION & LOCATION") {
                    emojiGrid(emojis: directionEmojis)
                }
                
                if searchText.isEmpty {
                    ForEach(categoryEmojis, id: \.0) { category, emojis in
                        Section(category.uppercased()) {
                            emojiGrid(emojis: emojis)
                        }
                    }
                } else {
                    ForEach(filteredEmojis, id: \.0) { category, emojis in
                        Section(category.uppercased()) {
                            emojiGrid(emojis: emojis)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Emojis")
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        logger.debug("User cancelled emoji selection", category: .userInterface)
                        dismiss()
                    }
                    .disabled(isProcessingSelection)
                }
            }
            .onAppear {
                logger.debug("EmojiPicker appeared with current emoji: '\(selectedEmoji)'", category: .userInterface)
            }
            .onChange(of: searchText) { _, newValue in
                logger.debug("Search text changed to: '\(newValue)'", category: .userInterface)
            }
            .disabled(isProcessingSelection)
        }
    }
} 