import SwiftUI
import AppKit

// MARK: - 设置页面通用组件

// MARK: - 设置区域组件
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(.leading, 22)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .opacity(0.5)
        )
    }
}

// MARK: - 设置开关组件
struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?
    
    init(title: String, subtitle: String, isOn: Binding<Bool>, onChange: ((Bool) -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onChange = onChange
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if #available(macOS 14.0, *) {
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: isOn) { _, newValue in
                        onChange?(newValue)
                    }
            } else {
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: isOn) { newValue in
                        onChange?(newValue)
                    }
            }
        }
    }
}

// MARK: - 设置选择器组件
struct SettingsPicker<T: Hashable>: View {
    let title: String
    let subtitle: String
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option)).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(minWidth: 120)
        }
    }
}

// MARK: - 设置按钮组件
struct SettingsButton: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, destructive
        
        var color: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .secondary
            case .destructive: return .red
            }
        }
        
        var buttonStyle: any PrimitiveButtonStyle {
            switch self {
            case .primary: return .borderedProminent
            case .secondary: return .bordered
            case .destructive: return .borderedProminent
            }
        }
    }
    
    init(title: String, subtitle: String? = nil, icon: String? = nil, style: ButtonStyle = .secondary, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 如果有subtitle，显示标题和描述
            if let subtitle = subtitle {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // 按钮，根据样式选择不同的风格
                if style == .primary || style == .destructive {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            if let icon = icon {
                                Image(systemName: icon)
                                    .font(.system(size: 13))
                            }
                            Text(title)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .accentColor(style.color)
                } else {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            if let icon = icon {
                                Image(systemName: icon)
                                    .font(.system(size: 13))
                            }
                            Text(title)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .accentColor(style.color)
                }
            } else {
                // 没有subtitle时，显示完整的按钮
                if style == .primary || style == .destructive {
                    Button(action: action) {
                        HStack {
                            if let icon = icon {
                                Image(systemName: icon)
                                    .font(.system(size: 13))
                            }
                            Text(title)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .accentColor(style.color)
                } else {
                    Button(action: action) {
                        HStack {
                            if let icon = icon {
                                Image(systemName: icon)
                                    .font(.system(size: 13))
                            }
                            Text(title)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .accentColor(style.color)
                }
            }
        }
    }
}

// MARK: - 设置输入框组件
struct SettingsTextField: View {
    let title: String
    let subtitle: String?
    let placeholder: String
    @Binding var text: String
    let onCommit: (() -> Void)?
    
    init(title: String, subtitle: String? = nil, placeholder: String, text: Binding<String>, onCommit: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.placeholder = placeholder
        self._text = text
        self.onCommit = onCommit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onCommit?()
                }
        }
    }
}

// MARK: - 设置滑块组件
struct SettingsSlider: View {
    let title: String
    let subtitle: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formatter: NumberFormatter
    
    init(title: String, subtitle: String? = nil, value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1.0) {
        self.title = title
        self.subtitle = subtitle
        self._value = value
        self.range = range
        self.step = step
        
        self.formatter = NumberFormatter()
        self.formatter.numberStyle = .decimal
        self.formatter.maximumFractionDigits = step < 1 ? 1 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formatter.string(from: NSNumber(value: value)) ?? "\(value)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 40)
            }
            
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - 设置信息卡片
struct SettingsInfoCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
}

// MARK: - 设置分隔线
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.vertical, 8)
    }
}

// MARK: - 设置页面标题
struct SettingsPageHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 设置列表项
struct SettingsListItem: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 真实直尺样式滑块组件
struct RulerSlider: View {
    let title: String
    let subtitle: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let majorTickInterval: Double
    let minorTickInterval: Double
    
    @State private var isDragging = false
    @State private var dragStartValue: Double = 0
    @State private var dragStartLocation: CGFloat = 0
    
    private let rulerHeight: CGFloat = 80
    private let tickHeight: CGFloat = 6
    private let majorTickHeight: CGFloat = 12
    private let mediumTickHeight: CGFloat = 9
    
    init(
        title: String,
        subtitle: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1.0,
        majorTickInterval: Double = 100,
        minorTickInterval: Double = 10
    ) {
        self.title = title
        self.subtitle = subtitle
        self._value = value
        self.range = range
        self.step = step
        self.majorTickInterval = majorTickInterval
        self.minorTickInterval = minorTickInterval
    }
    
        var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和当前值显示
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                // 当前值显示（像真实直尺的读数窗口）
                Text("\(Int(value))")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundColor(.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.yellow, lineWidth: 1)
                            )
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isDragging)
            }
            
            // 真实直尺容器
            GeometryReader { geometry in
                let availableWidth = geometry.size.width - 20 // 留出边距
                
                ZStack {
                    // 直尺背景（木质纹理效果）
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(Color(red: 0.96, green: 0.87, blue: 0.70)) // 木质颜色
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.brown.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    VStack(spacing: 0) {
                        // 刻度和数字区域
                        HStack(spacing: 0) {
                            let tickPositions = generateTickPositions(availableWidth)
                            ForEach(Array(tickPositions.enumerated()), id: \.offset) { index, tickValue in
                                let isMajorTick = Int(tickValue) % Int(majorTickInterval) == 0 // 每100单位
                                
                                VStack(spacing: 1) {
                                    // 数字标签（只在主刻度显示）
                                    if isMajorTick && tickValue >= range.lowerBound && tickValue <= range.upperBound {
                                        Text("\(Int(tickValue))")
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundColor(.black.opacity(0.8))
                                            .lineLimit(1)
                                            .fixedSize()
                                    } else {
                                        Spacer()
                                            .frame(height: 14)
                                    }
                                    
                                    // 刻度线
                                    Rectangle()
                                        .foregroundColor(.black.opacity(isMajorTick ? 0.8 : 0.5))
                                        .frame(
                                            width: 1,
                                            height: isMajorTick ? majorTickHeight : mediumTickHeight
                                        )
                                }
                                .frame(maxWidth: .infinity) // 平均分配空间
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 8)
                        
                        Spacer()
                        
                        // 滑动指示器（红色指针）
                        ZStack {
                            // 指针背景轨道
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 20)
                            
                            // 红色指针 - 修正位置计算
                            HStack {
                                Rectangle()
                                    .foregroundColor(.red)
                                    .frame(width: isDragging ? 3 : 2, height: 20)
                                    .shadow(color: .red.opacity(0.5), radius: isDragging ? 4 : 2)
                                    .animation(.easeInOut(duration: 0.15), value: isDragging)
                                
                                Spacer()
                            }
                            .offset(x: getProgressWidth(availableWidth))
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                    }
                }
                .frame(height: rulerHeight)
                .gesture(
                    DragGesture()
                        .onChanged { gestureValue in
                            handleDrag(gestureValue, availableWidth: availableWidth)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: rulerHeight)
            .padding(.horizontal, 10)
        }
    }
    
    // MARK: - 计算方法
    
    private func getProgressWidth(_ availableWidth: CGFloat) -> CGFloat {
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return max(0, min(availableWidth, availableWidth * progress))
    }
    
    private func getTickPosition(for tickValue: Double, availableWidth: CGFloat) -> CGFloat {
        let progress = (tickValue - range.lowerBound) / (range.upperBound - range.lowerBound)
        return progress * availableWidth
    }
    
    private func generateTickPositions(_ availableWidth: CGFloat) -> [Double] {
        var positions: [Double] = []
        
        // 使用固定的50单位间隔生成所有刻度位置
        let tickInterval: Double = 50
        
        // 生成从0到1000的所有50单位刻度
        var currentValue: Double = 0
        while currentValue <= range.upperBound {
            if currentValue >= range.lowerBound {
                positions.append(currentValue)
            }
            currentValue += tickInterval
        }
        
        return positions.sorted()
    }
    
    private func handleDrag(_ gestureValue: DragGesture.Value, availableWidth: CGFloat) {
        if !isDragging {
            isDragging = true
            dragStartValue = value
            dragStartLocation = gestureValue.startLocation.x
        }
        
        // 计算拖拽偏移量
        let dragOffset = gestureValue.location.x - dragStartLocation
        let valueRange = range.upperBound - range.lowerBound
        let pixelsPerUnit = availableWidth / CGFloat(valueRange)
        let valueDelta = Double(dragOffset / pixelsPerUnit)
        
        // 计算新值
        let newValue = dragStartValue + valueDelta
        let steppedValue = round(newValue / step) * step
        
        // 限制在范围内并实时更新
        value = max(range.lowerBound, min(range.upperBound, steppedValue))
    }
} 
