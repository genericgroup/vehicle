import SwiftUI

/// A picker view for selecting vehicle colors
struct ColorPickerView: View {
    @Binding var selection: String
    let logger: AppLogger
    
    init(selection: Binding<String>, logger: AppLogger = AppLogger.shared) {
        self._selection = selection
        self.logger = logger
    }
    
    var body: some View {
        Picker("Color", selection: $selection) {
            ForEach(Vehicle.commonColors, id: \.self) { colorName in
                ColorPickerRow(colorName: colorName)
                    .tag(colorName)
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            logger.debug("Color changed from \(oldValue) to \(newValue)", category: .userInterface)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .foregroundStyle(.primary)
    }
}

/// A row displaying a color name with a color swatch
struct ColorPickerRow: View {
    let colorName: String
    
    var body: some View {
        HStack {
            Text(colorName)
                .foregroundStyle(.primary)
            Spacer()
            if colorName != "Custom" {
                ZStack {
                    if colorName == "White" {
                        Circle()
                            .stroke(.black, lineWidth: 1)
                            .frame(width: 12, height: 12)
                    }
                    if colorName == "Black" {
                        Circle()
                            .stroke(.white, lineWidth: 1)
                            .frame(width: 12, height: 12)
                    }
                    Image(systemName: "circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(ColorUtility.color(from: colorName), ColorUtility.color(from: colorName).opacity(0.3))
                        .font(.system(size: 12))
                }
            }
        }
        .frame(minWidth: 100, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    Form {
        ColorPickerView(selection: .constant("Blue"))
    }
}
