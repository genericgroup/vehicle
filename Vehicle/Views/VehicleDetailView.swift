import SwiftUI
import SwiftData
import PDFKit
import AVFoundation
import Photos
import Observation
import PhotosUI
import UniformTypeIdentifiers

// Helper extension for conditional view modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct CategorizationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vehicle: Vehicle
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
            LabeledContent("Category") {
                Picker("", selection: $vehicle.category) {
                    ForEach(VehicleType.allTypes, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }
            
            LabeledContent("Subcategory") {
                Picker("", selection: Binding(
                    get: { vehicle.subcategory },
                    set: { vehicle.subcategory = $0 }
                )) {
                    Text("Not Set").tag(nil as VehicleSubcategory?)
                    ForEach(vehicle.category.subcategories, id: \.self) { subcategory in
                        Text(subcategory.displayName).tag(subcategory)
                    }
                }
                .onChange(of: vehicle.subcategory) { _, _ in
                    vehicle.vehicleType = nil
                }
            }
            
            if let subcategory = vehicle.subcategory {
                LabeledContent("Type") {
                    Picker("", selection: Binding(
                        get: { vehicle.vehicleType },
                        set: { vehicle.vehicleType = $0 }
                    )) {
                        Text("Not Set").tag(nil as VehicleTypeDetail?)
                        ForEach(subcategory.types, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categorization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vehicle: Vehicle
    @FocusState private var internalFocusedField: Bool
    @State private var validationError: String?
    @State private var showingValidationError = false
    @State private var localVehicle: Vehicle
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        // Create a local copy for editing
        _localVehicle = State(initialValue: vehicle)
    }
    
    private func saveChanges() {
        // Validate fields in order, top to bottom
        if let trimLevel = localVehicle.trimLevel {
            let validation = VehicleValidation.validateTrimLevel(trimLevel)
            if !validation.isValid {
                validationError = validation.message
                showingValidationError = true
                return
            }
        }
        
        if let vin = localVehicle.vin {
            let validation = VehicleValidation.validateVIN(vin, category: localVehicle.category, year: localVehicle.year)
            if !validation.isValid {
                validationError = validation.message
                showingValidationError = true
                return
            }
        }
        
        if let serialNumber = localVehicle.serialNumber {
            let validation = VehicleValidation.validateSerialNumber(serialNumber)
            if !validation.isValid {
                validationError = validation.message
                showingValidationError = true
                return
            }
        }
        
        // If all validations pass, copy values to original vehicle
        vehicle.trimLevel = localVehicle.trimLevel
        vehicle.vin = localVehicle.vin?.uppercased()
        vehicle.serialNumber = localVehicle.serialNumber
        vehicle.fuelType = localVehicle.fuelType
        vehicle.engineType = localVehicle.engineType
        vehicle.driveType = localVehicle.driveType
        vehicle.transmissionType = localVehicle.transmissionType
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Trim Level") {
                        TextField("Optional", text: Binding(
                            get: { localVehicle.trimLevel ?? "" },
                            set: { newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                localVehicle.trimLevel = trimmed.isEmpty ? nil : trimmed
                            }
                        ))
                        .focused($internalFocusedField)
                        .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("VIN") {
                        TextField("Optional", text: Binding(
                            get: { localVehicle.vin ?? "" },
                            set: { newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                localVehicle.vin = trimmed.isEmpty ? nil : trimmed.uppercased()
                            }
                        ))
                        .focused($internalFocusedField)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.characters)
                    }
                    
                    LabeledContent("Serial Number") {
                        TextField("Optional", text: Binding(
                            get: { localVehicle.serialNumber ?? "" },
                            set: { newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                localVehicle.serialNumber = trimmed.isEmpty ? nil : trimmed
                            }
                        ))
                        .focused($internalFocusedField)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.characters)
                    }
                    
                    LabeledContent("Fuel Type") {
                        Picker("", selection: $localVehicle.fuelType) {
                            ForEach(FuelType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                    
                    LabeledContent("Engine Type") {
                        Picker("", selection: $localVehicle.engineType) {
                            ForEach(EngineType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                    
                    LabeledContent("Drive Type") {
                        Picker("", selection: $localVehicle.driveType) {
                            ForEach(DriveType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                    
                    LabeledContent("Transmission") {
                        Picker("", selection: $localVehicle.transmissionType) {
                            ForEach(TransmissionType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                }
                .alert("Validation Error", isPresented: $showingValidationError) {
                    Button("OK") {
                        showingValidationError = false
                    }
                } message: {
                    Text(validationError ?? "Invalid input")
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }
}

struct AttachmentsListView: View {
    @Bindable var vehicle: Vehicle
    @Environment(\.modelContext) private var modelContext
    let onDelete: ([Attachment]) -> Void
    let onSelect: (Attachment) -> Void
    
    var body: some View {
        if let attachments = vehicle.attachments, !attachments.isEmpty {
            Section {
                ForEach(attachments.sorted(by: { $0.addedDate > $1.addedDate })) { attachment in
                    AttachmentRow(attachment: attachment)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(attachment)
                        }
                        .contextMenu {
                            ShareLink(item: attachment.data, preview: SharePreview(attachment.displayName))
                            Button(role: .destructive) {
                                onDelete([attachment])
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete { indexSet in
                    let sortedAttachments = attachments.sorted(by: { $0.addedDate > $1.addedDate })
                    let toDelete = indexSet.map { sortedAttachments[$0] }
                    onDelete(toDelete)
                }
            }
        } else {
            Section {
                ContentUnavailableView("No Attachments", 
                    systemImage: "doc",
                    description: Text("Add files, images, or audio recordings")
                )
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
    }
}

struct AttachmentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var vehicle: Vehicle
    @State private var showingFilePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedAttachment: Attachment?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var importProgress: ImportProgress?
    @State private var attachmentsToDelete: [Attachment] = []
    
    private let logger = AppLogger.shared
    private let maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB
    
    var body: some View {
        NavigationStack {
            List {
                AttachmentsListView(
                    vehicle: vehicle,
                    onDelete: { attachments in
                        attachmentsToDelete = attachments
                        showingDeleteConfirmation = true
                    },
                    onSelect: { attachment in
                        selectedAttachment = attachment
                    }
                )
                
                Section {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Add Attachment", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Attachments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if let progress = importProgress {
                    VStack {
                        ProgressView(value: progress.percentage, total: 100) {
                            Text("Importing \(progress.current) of \(progress.total)")
                                .font(.caption)
                        } currentValueLabel: {
                            Text(progress.currentFileName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .progressViewStyle(.linear)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [
                    .image,
                    .pdf,
                    .audio,
                    .plainText,
                    .rtf,
                    UTType("com.microsoft.word.doc")!,
                    UTType("org.openxmlformats.wordprocessingml.document")!
                ],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    Task {
                        await importFiles(urls)
                    }
                case .failure(let error):
                    logger.error("Failed to import files: \(error.localizedDescription)", category: .fileSystem)
                    errorMessage = "Failed to import files: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
            .sheet(item: $selectedAttachment) { attachment in
                NavigationStack {
                    AttachmentDetailView(attachment: attachment)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    selectedAttachment = nil
                                }
                            }
                            ToolbarItem(placement: .primaryAction) {
                                ShareLink(item: attachment.data, preview: SharePreview(attachment.displayName))
                            }
                        }
                }
                .presentationDragIndicator(.visible)
            }
            .alert("Validation Error", isPresented: $showingErrorAlert) {
                Button("OK") {
                    showingErrorAlert = false
                }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Attachment?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    HapticManager.standardButtonTap()
                }
                Button("Delete", role: .destructive) {
                    HapticManager.standardDelete()
                    deleteSelectedAttachment()
                }
            } message: {
                Text("Are you sure you want to delete this attachment? This action cannot be undone.")
            }
        }
    }
    
    private func importFiles(_ urls: [URL]) async {
        importProgress = ImportProgress(total: urls.count, current: 0, currentFileName: "")
        
        // Check if any files are images that require photo library permission
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff"]
        let hasImageFiles = urls.contains { url in
            imageExtensions.contains(url.pathExtension.lowercased())
        }
        
        // Only request photo library permission if importing images
        if hasImageFiles {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if status != .authorized && status != .limited {
                // Log but don't block - we can still import from Files without photo library access
                logger.warning("Photo library access not granted, but continuing with file import", category: .fileSystem)
            }
        }
        
        for (index, url) in urls.enumerated() {
            importProgress?.current = index + 1
            importProgress?.currentFileName = url.lastPathComponent
            
            do {
                // Start accessing the security scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw ImportError.accessDenied(url.lastPathComponent)
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                try await importLargeFile(url)
            } catch let error as ImportError {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            } catch {
                logger.error("Failed to import file \(url.lastPathComponent): \(error.localizedDescription)", category: .fileSystem)
                errorMessage = "Failed to import \(url.lastPathComponent): \(error.localizedDescription)"
                showingErrorAlert = true
            }
        }
        
        await MainActor.run {
            importProgress = nil
        }
    }
    
    private func importLargeFile(_ url: URL) async throws {
        let fileName = url.lastPathComponent
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = resourceValues.fileSize ?? 0
        
        // If file is larger than 10MB, use background transfer
        if fileSize > 10 * 1024 * 1024 {
            let tempURL = try await BackgroundTransferManager.shared.startUpload(
                data: try await url.loadData(),
                fileName: fileName
            )
            
            // Start the background upload
            let backgroundTask = UIApplication.shared.beginBackgroundTask {
                // Handle background task expiration
                logger.warning("Background task expired for \(fileName)", category: .fileSystem)
            }
            
            defer {
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }
            
            do {
                // Process the file after upload completes
                let data = try Data(contentsOf: tempURL)
                try await processImportedFile(data: data, originalURL: url)
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: tempURL)
            } catch {
                throw error
            }
        } else {
            // For smaller files, use the regular import process
            let data = try await url.loadData()
            try await processImportedFile(data: data, originalURL: url)
        }
    }
    
    private func processImportedFile(data: Data, originalURL url: URL) async throws {
        let fileExtension = url.pathExtension.lowercased()
        
        // Perform all the existing validation checks
        guard isValidFileExtension(fileExtension) else {
            throw ImportError.unsupportedFileType(fileExtension)
        }
        
        // Validate file size
        guard data.count <= maxFileSize else {
            throw ImportError.fileTooLarge(Int64(data.count))
        }
        
        // Create and save the attachment
        await MainActor.run {
            let attachment = Attachment(
                fileName: url.deletingPathExtension().lastPathComponent,
                fileExtension: fileExtension,
                mimeType: getMimeType(for: fileExtension),
                data: data,
                vehicle: vehicle
            )
            
            if vehicle.attachments == nil {
                vehicle.attachments = []
            }
            vehicle.attachments?.append(attachment)
            logger.debug("Added attachment: \(attachment.displayName)", category: .database)
            HapticManager.shared.notifySuccess()
        }
    }
    
    private enum ImportError: LocalizedError {
        case unsupportedFileType(String)
        case fileTooLarge(Int64)
        case accessDenied(String)
        
        var errorDescription: String? {
            switch self {
            case .unsupportedFileType(let ext):
                return "Unsupported file type: \(ext). Supported formats:\n" +
                    "• Images: JPG, JPEG, PNG, HEIC, HEIF\n" +
                    "• Documents: PDF, DOCX, DOC, TXT, RTF\n" +
                    "• Audio: M4A, WAV, MP3"
            case .fileTooLarge(let size):
                return "File exceeds 50MB limit: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))"
            case .accessDenied(let filename):
                return "Permission denied to access file: \(filename). Please ensure the app has the necessary permissions."
            }
        }
    }
    
    private func isValidFileExtension(_ fileExtension: String) -> Bool {
        let validExtensions = [
            // Images
            "jpg", "jpeg", "png", "heic", "heif",
            // Documents
            "pdf", "docx", "doc", "txt", "rtf",
            // Audio
            "m4a", "wav", "mp3"
        ]
        return validExtensions.contains(fileExtension)
    }
    
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension {
        // Images
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        case "heif":
            return "image/heif"
        // Documents
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "txt":
            return "text/plain"
        case "rtf":
            return "application/rtf"
        // Audio
        case "m4a":
            return "audio/m4a"
        case "wav":
            return "audio/wav"
        case "mp3":
            return "audio/mpeg"
        default:
            return "application/octet-stream"
        }
    }
    
    private func deleteSelectedAttachment() {
        if let selectedAttachment = selectedAttachment {
            vehicle.attachments?.removeAll { $0.id == selectedAttachment.id }
            modelContext.delete(selectedAttachment)
            logger.debug("Deleted attachment: \(selectedAttachment.displayName)", category: .database)
            HapticManager.shared.notifySuccess()
        }
    }
    
    private func deleteAttachments(_ attachments: [Attachment]) {
        for attachment in attachments {
            vehicle.attachments?.removeAll { $0.id == attachment.id }
            modelContext.delete(attachment)
            logger.debug("Deleted attachment: \(attachment.displayName)", category: .database)
        }
        HapticManager.shared.notifySuccess()
    }
}

struct AttachmentRow: View {
    let attachment: Attachment
    @State private var thumbnail: UIImage?
    
    var body: some View {
        HStack {
            if attachment.isImage {
                Group {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                }
            } else {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            
            VStack(alignment: .leading) {
                Text(attachment.displayName)
                HStack {
                    Text(attachment.addedDate.formatted(date: .numeric, time: .shortened))
                    Text("•")
                    Text(ByteCountFormatter.string(fromByteCount: Int64(attachment.data.count), countStyle: .file))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .task {
            if attachment.isImage {
                thumbnail = await attachment.thumbnail
            }
        }
    }
    
    private var iconName: String {
        if attachment.isPDF {
            return "doc.text.fill"
        } else if attachment.isAudio {
            return "waveform"
        } else {
            let ext = attachment.fileExtension.lowercased()
            switch ext {
            case "doc", "docx":
                return "doc.fill"
            case "txt":
                return "doc.plaintext.fill"
            case "rtf":
                return "doc.richtext.fill"
            default:
                return "doc"
            }
        }
    }
}

struct AttachmentDetailView: View {
    let attachment: Attachment
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var imageScale: CGFloat = 1.0
    
    var body: some View {
        Group {
            if let error = loadError {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription))
            } else {
                if attachment.isImage {
                    if let uiImage = UIImage(data: attachment.data) {
                        GeometryReader { geometry in
                            ScrollView([.horizontal, .vertical]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width * imageScale)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { scale in
                                                imageScale = scale.magnitude
                                            }
                                    )
                            }
                        }
                    } else {
                        ContentUnavailableView("Invalid Image", systemImage: "photo.badge.exclamationmark")
                    }
                } else if attachment.isPDF {
                    PDFKitView(data: attachment.data)
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }
                        }
                } else if attachment.isAudio {
                    AudioPlayerView(data: attachment.data)
                }
            }
        }
        .navigationTitle(attachment.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Add a brief delay to show loading state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoading = false
            }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFKit.PDFView {
        let pdfView = PDFKit.PDFView()
        pdfView.document = PDFKit.PDFDocument(data: data)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFKit.PDFView, context: Context) {}
}

struct AudioPlayerView: View {
    let data: Data
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text(timeString(currentTime))
                .font(.title2.monospacedDigit())
                .foregroundStyle(.secondary)
            
            HStack {
                Button {
                    if isPlaying {
                        player?.pause()
                    } else {
                        player?.play()
                    }
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                
                if let duration = player?.duration {
                    Slider(value: $currentTime, in: 0...duration) { editing in
                        if editing {
                            player?.pause()
                        } else {
                            player?.currentTime = currentTime
                            if isPlaying {
                                player?.play()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            do {
                player = try AVAudioPlayer(data: data)
                player?.prepareToPlay()
            } catch {
                print("Failed to create audio player: \(error)")
            }
        }
        .onReceive(timer) { _ in
            guard let player = player, isPlaying else { return }
            currentTime = player.currentTime
            if !player.isPlaying {
                isPlaying = false
                currentTime = 0
            }
        }
    }
    
    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct VehicleInfoSection: View {
    @Bindable var vehicle: Vehicle
    @FocusState.Binding var focusedField: Bool
    @Binding var showingEmojiPicker: Bool
    @ObservedObject var sheetManager: SheetManager
    let logger: AppLogger
    
    private let rowHeight: CGFloat = 38  // Reduced from 44 to 38
    
    var body: some View {
        Section {
            // Basic Information
            LabeledContent("Make") {
                TextField("Required", text: Binding(
                    get: { vehicle.make },
                    set: { vehicle.make = $0.trimmingCharacters(in: .whitespaces) }
                ))
                .focused($focusedField)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
            }
            .frame(height: rowHeight)
            
            LabeledContent("Model") {
                TextField("Required", text: Binding(
                    get: { vehicle.model },
                    set: { vehicle.model = $0.trimmingCharacters(in: .whitespaces) }
                ))
                .focused($focusedField)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
            }
            .frame(height: rowHeight)
            
            LabeledContent("Year") {
                Picker("", selection: $vehicle.year) {
                    ForEach(Array(1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                        Text(String(year))
                            .tag(year)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .frame(height: rowHeight)
            
            LabeledContent("Color") {
                ColorPickerView(selection: $vehicle.color, logger: logger)
            }
            .foregroundStyle(.primary)
            .frame(height: rowHeight)
            
            LabeledContent("Nickname") {
                TextField("Optional", text: Binding(
                    get: { vehicle.nickname ?? "" },
                    set: { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                        vehicle.nickname = trimmed.isEmpty ? nil : trimmed
                    }
                ))
                .focused($focusedField)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.primary)
            }
            .frame(height: rowHeight)
            
            LabeledContent("Icon") {
            Button(action: { 
                HapticManager.shared.selectionChanged()
                    showingEmojiPicker = true 
                }) {
                    if vehicle.icon.isEmpty {
                        Text("None")
                            .foregroundStyle(.primary)
                    } else {
                        Text(vehicle.icon)
                            .font(.title2)
                    }
                }
            }
            .frame(height: rowHeight)
            
            // Categorization Button
            Button(action: {
                HapticManager.shared.selectionChanged()
                sheetManager.presentSheet(.categorization)
            }) {
                HStack {
                    Text("Categorization")
                    Spacer()
                    Text(getMostSpecificCategory(vehicle))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(height: rowHeight)
            .foregroundStyle(.primary)
            
            // Details Button
            Button(action: {
                HapticManager.shared.selectionChanged()
                sheetManager.presentSheet(.details)
            }) {
                HStack {
                    Text("Details")
                    Spacer()
                    if let trimLevel = vehicle.trimLevel, !trimLevel.isEmpty {
                        Text(trimLevel)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(vehicle.fuelType.displayName)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .frame(height: rowHeight)
            .foregroundStyle(.primary)
            
            // Notes Button
            Button(action: {
                HapticManager.shared.selectionChanged()
                sheetManager.presentSheet(.notes)
            }) {
                HStack {
                    Text("Notes")
                    Spacer()
                    if let notes = vehicle.notes {
                        Text(notes.prefix(30) + (notes.count > 30 ? "..." : ""))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                    }
                }
            }
            .frame(height: rowHeight)
            .foregroundStyle(.primary)
            
            // Attachments Button
            Button(action: { 
                HapticManager.shared.selectionChanged()
                sheetManager.presentSheet(.attachments)
            }) {
                HStack {
                    Text("Attachments")
                    Spacer()
                    Text(vehicle.attachments?.count ?? 0 > 0 ? "\(vehicle.attachments?.count ?? 0)" : "None")
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(height: rowHeight)
            .foregroundStyle(.primary)
        }
    }
    
    private func getMostSpecificCategory(_ vehicle: Vehicle) -> String {
        if let type = vehicle.vehicleType {
            return type.displayName
        }
        if let subcategory = vehicle.subcategory {
            return subcategory.displayName
        }
        return vehicle.category.displayName
    }
}

struct VehicleDetailView: View {
    @Bindable var vehicle: Vehicle
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Bool
    @StateObject private var sheetManager = SheetManager(logger: AppLogger.shared)
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteAttachmentConfirmation = false
    @State private var showingEmojiPicker = false
    @State private var showingEventSheet = false
    @State private var showingOwnershipSheet = false
    @State private var showingShareSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingValidationError = false
    @State private var validationError: String?
    @State private var pdfURL: URL?
    @AppStorage(AppStorageKeys.showIconsInList) private var showIconsInList = true
    
    private let logger = AppLogger.shared
    
    private var navigationTitle: String {
        if showIconsInList && !vehicle.icon.isEmpty {
            return "\(vehicle.icon) \(vehicle.displayName)"
        } else {
            return vehicle.displayName
        }
    }
    
    private func deleteSelectedAttachment() {
        // Implementation will be added when attachment functionality is implemented
        logger.debug("Delete attachment requested", category: .userInterface)
    }

    var body: some View {
        Form {
            VehicleInfoSection(
                vehicle: vehicle,
                focusedField: $focusedField,
                showingEmojiPicker: $showingEmojiPicker,
                sheetManager: sheetManager,
                logger: logger
            )
            
            VehicleEventsSection(
                vehicle: vehicle,
                showingEventSheet: $showingEventSheet
            )
            
            VehicleOwnershipSection(
                vehicle: vehicle,
                showingOwnershipSheet: $showingOwnershipSheet
            )
            
            Section {
                Button {
                    HapticManager.standardButtonTap()
                    vehicle.isPinned.toggle()
                } label: {
                    Label(
                        vehicle.isPinned ? "Unpin from Top" : "Pin to Top",
                        systemImage: vehicle.isPinned ? "pin.slash.fill" : "pin.fill"
                    )
                }
                .tint(vehicle.isPinned ? .red : .blue)
                .accessibilityLabel(vehicle.isPinned ? "Unpin vehicle" : "Pin vehicle")
                .accessibilityHint(vehicle.isPinned ? "Remove from top of list" : "Move to top of list")
                
                standardDeleteButton(title: "Delete Vehicle") {
                    HapticManager.standardWarning()
                    showingDeleteConfirmation = true
                }
            }
        }
        .standardFormStyle()
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.standardButtonTap()
                    sharePDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
                .accessibilityHint("Export vehicle details as PDF")
            }
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPicker(selectedEmoji: $vehicle.icon)
        }
        .sheet(isPresented: $showingEventSheet) {
            NavigationStack {
                AddEventView(selectedVehicle: vehicle)
            }
            .interactiveDismissDisabled()
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingOwnershipSheet) {
            NavigationStack {
                AddOwnershipView(selectedVehicle: vehicle)
            }
            .interactiveDismissDisabled()
            .presentationDragIndicator(.visible)
        }
        .sheet(item: sheetManager.activeSheetBinding) { sheet in
            VehicleDetailSheetContent(sheet: sheet, vehicle: vehicle, logger: logger)
        }
        .alert("Validation Error", isPresented: $showingValidationError) {
            Button("OK") {
                HapticManager.standardButtonTap()
                showingValidationError = false
            }
        } message: {
            Text(validationError ?? "Invalid input")
        }
        .alert("Delete Vehicle?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                HapticManager.standardButtonTap()
            }
            Button("Delete", role: .destructive) {
                HapticManager.standardDelete()
                deleteVehicle()
            }
        } message: {
            Text("Are you sure you want to delete this vehicle? This action cannot be undone.")
        }
        .alert("Delete Attachment?", isPresented: $showingDeleteAttachmentConfirmation) {
            Button("Cancel", role: .cancel) {
                HapticManager.standardButtonTap()
            }
            Button("Delete", role: .destructive) {
                HapticManager.standardDelete()
                deleteSelectedAttachment()
            }
        } message: {
            Text("Are you sure you want to delete this attachment? This action cannot be undone.")
        }
        .alert("Validation Error", isPresented: $showingError) {
            Button("OK") {
                HapticManager.standardButtonTap()
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url], filename: pdfFilename)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Generating PDF...")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            }
        }
    }
    
    private func deleteVehicle() {
        HapticManager.shared.notifySuccess()
                modelContext.delete(vehicle)
        logger.info("Vehicle deleted: \(vehicle.displayName)", category: .database)
    }
    
    private func validateVehicle() {
        logger.debug("Validating vehicle: \(vehicle.displayName)", category: .database)
    }
    
    private func sharePDF() {
        Task {
            // Show loading state
            await MainActor.run {
                pdfURL = nil
                showingShareSheet = true
            }
            
            // Generate PDF in background
            let url = await Task.detached(priority: .userInitiated) { [vehicle] () -> URL? in 
                PDFGenerator.generateVehiclePDF(vehicle)
            }.value
            
            // Update UI on main thread
            await MainActor.run {
                if let url = url {
                    self.pdfURL = url
                } else {
                    logger.error("Failed to generate PDF", category: .fileSystem)
                    // Hide sheet if generation failed
                    self.showingShareSheet = false
                    // Show error alert
                    self.errorMessage = "Failed to generate PDF"
                    self.showingError = true
                }
            }
        }
    }
    
    private var pdfFilename: String {
        // Sanitize filename to remove invalid characters
        let sanitizedName = vehicle.displayName
            .components(separatedBy: .init(charactersIn: "/\\?%*|\"<>"))
            .joined()
            .trimmingCharacters(in: .whitespaces)
        
        return "\(sanitizedName) \(vehicle.year).pdf"
    }
    
    private func updateVehicle() {
        vehicle.make = vehicle.make.trimmingCharacters(in: .whitespaces)
        vehicle.model = vehicle.model.trimmingCharacters(in: .whitespaces)
        
        do {
            try modelContext.save()
            logger.info("Successfully updated vehicle", category: .database)
            HapticManager.shared.notifySuccess()
                dismiss()
        } catch {
            logger.error("Failed to update vehicle: \(error.localizedDescription)", category: .database)
            HapticManager.shared.notifyError()
            showError("Failed to update vehicle")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension URL {
    func loadData() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: self)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Attachment Utilities
struct ImportProgress {
    let total: Int
    var current: Int
    var currentFileName: String
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100
    }
}

private extension FileManager {
    static let attachmentCacheURL: URL = {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let attachmentCache = cacheDirectory.appendingPathComponent("AttachmentCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: attachmentCache, withIntermediateDirectories: true)
        return attachmentCache
    }()
    
    func clearAttachmentCache() {
        try? FileManager.default.removeItem(at: Self.attachmentCacheURL)
        try? FileManager.default.createDirectory(at: Self.attachmentCacheURL, withIntermediateDirectories: true)
    }
}

extension Attachment {
    func generateThumbnail() -> UIImage? {
        guard isImage, let image = UIImage(data: data) else { return nil }
        let size = CGSize(width: 120, height: 120)
        return image.preparingThumbnail(of: size)
    }
    
    var thumbnail: UIImage? {
        get async {
            if let cached = try? await loadThumbnailFromCache() {
                return cached
            }
            let thumbnail = generateThumbnail()
            await saveThumbnailToCache(thumbnail)
            return thumbnail
        }
    }
    
    private func loadThumbnailFromCache() async throws -> UIImage? {
        let cacheURL = FileManager.attachmentCacheURL.appendingPathComponent("\(id)-thumb.jpg")
        let data = try Data(contentsOf: cacheURL)
        return UIImage(data: data)
    }
    
    private func saveThumbnailToCache(_ thumbnail: UIImage?) async {
        guard let thumbnail = thumbnail,
              let data = thumbnail.jpegData(compressionQuality: 0.8) else { return }
        let cacheURL = FileManager.attachmentCacheURL.appendingPathComponent("\(id)-thumb.jpg")
        try? data.write(to: cacheURL)
    }
    
    func cachedData() async throws -> Data {
        let cacheURL = FileManager.attachmentCacheURL.appendingPathComponent(id)
        if let cached = try? Data(contentsOf: cacheURL) {
            return cached
        }
        try data.write(to: cacheURL)
        return data
    }
}

private func compressImageIfNeeded(_ data: Data, maxSize: Int = 1024 * 1024) -> Data {
    guard let image = UIImage(data: data) else { return data }
    
    var compression: CGFloat = 1.0
    var compressedData = image.jpegData(compressionQuality: compression) ?? data
    
    while compressedData.count > maxSize && compression > 0.1 {
        compression -= 0.1
        if let newData = image.jpegData(compressionQuality: compression) {
            compressedData = newData
        }
    }
    
    return compressedData.count < data.count ? compressedData : data
}

// MARK: - Background Transfer
private actor BackgroundTransferManager {
    static let shared = BackgroundTransferManager()
    private var backgroundSession: URLSession!
    private var transfers: [String: TransferProgress] = [:]
    private let logger = AppLogger.shared
    
    private init() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.vehicle.backgroundTransfer")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config)
    }
    
    func startUpload(data: Data, fileName: String) async throws -> URL {
        // Create a temporary file URL in the app's temporary directory
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(fileName)
        
        // Ensure the directory exists
        try FileManager.default.createDirectory(at: tempURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        // Write the data to the temporary file
        try data.write(to: tempURL)
        
        // Create a transfer record
        let transfer = TransferProgress(
            id: UUID().uuidString,
            fileName: fileName,
            size: Int64(data.count),
            type: .upload
        )
        transfers[transfer.id] = transfer
        
        logger.debug("Starting background upload for \(fileName)", category: .fileSystem)
        return tempURL
    }
    
    func startDownload(from url: URL, fileName: String) async throws -> URL {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(fileName)
        
        // Create the directory if it doesn't exist
        try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        // Create a transfer record
        let transfer = TransferProgress(
            id: UUID().uuidString,
            fileName: fileName,
            size: 0, // Will be updated when the response is received
            type: .download
        )
        transfers[transfer.id] = transfer
        
        logger.debug("Starting background download for \(fileName)", category: .fileSystem)
        return destinationURL
    }
    
    func updateProgress(for id: String, bytesTransferred: Int64, totalBytes: Int64) {
        if var transfer = transfers[id] {
            transfer.bytesTransferred = bytesTransferred
            transfer.size = totalBytes
            transfers[id] = transfer
            
            logger.debug("Transfer progress for \(transfer.fileName): \(transfer.progress)%", category: .fileSystem)
        }
    }
    
    func completeTransfer(for id: String, error: Error?) {
        if let transfer = transfers.removeValue(forKey: id) {
            if let error = error {
                logger.error("Transfer failed for \(transfer.fileName): \(error.localizedDescription)", category: .fileSystem)
            } else {
                logger.debug("Transfer completed for \(transfer.fileName)", category: .fileSystem)
            }
        }
    }
}

private struct TransferProgress: Identifiable {
    let id: String
    let fileName: String
    var bytesTransferred: Int64 = 0
    var size: Int64
    let type: TransferType
    
    var progress: Double {
        guard size > 0 else { return 0 }
        return Double(bytesTransferred) / Double(size) * 100
    }
    
    enum TransferType {
        case upload
        case download
    }
}

private struct VehicleDetailSheetContent: View {
    let sheet: SheetManager.Sheet
    @Bindable var vehicle: Vehicle
    let logger: AppLogger
    
    var body: some View {
        Group {
            switch sheet {
            case .categorization:
                CategorizationSheet(vehicle: vehicle)
                    .onAppear {
                        logger.debug("Categorization sheet appeared", category: .userInterface)
                    }
                    .onDisappear {
                        logger.debug("Categorization sheet disappeared", category: .userInterface)
                    }
                
            case .details:
                DetailsSheet(vehicle: vehicle)
                
            case .notes:
                NotesSheet(notes: Binding(
                    get: { vehicle.notes ?? "" },
                    set: { vehicle.notes = $0.isEmpty ? nil : $0 }
                ))
                
            case .attachments:
                AttachmentsSheet(vehicle: vehicle)
            }
        }
        .presentationDragIndicator(.visible)
    }
} 