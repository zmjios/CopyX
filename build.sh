#!/bin/bash
###
 # @Chinese description: enter your description
 # @English description: enter your description
 # @Autor: mjzeng
 # @Date: 2025-06-22 09:13:10
 # @LastEditors: mjzeng
 # @LastEditTime: 2025-06-23 15:36:45
### 

# CopyX 构建脚本
# 此脚本将编译应用并将其输出到 Products 文件夹

echo "🚀 开始构建 CopyX..."

# 清理之前的构建产物
echo "🧹 清理之前的构建产物..."
rm -rf Products/*

# 构建应用 (Debug 配置)
echo "🔨 构建 Debug 版本..."
xcodebuild -project CopyX.xcodeproj -scheme CopyX -configuration Debug build

if [ $? -eq 0 ]; then
    echo "✅ Debug 构建成功！"
    echo "📱 应用位置: $(pwd)/Products/CopyX.app"
    
    # 显示应用信息
    if [ -d "Products/CopyX.app" ]; then
        echo "📊 应用信息:"
        echo "   - 名称: $(defaults read "$(pwd)/Products/CopyX.app/Contents/Info.plist" CFBundleDisplayName 2>/dev/null || echo "CopyX")"
        echo "   - 版本: $(defaults read "$(pwd)/Products/CopyX.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")"
        echo "   - 大小: $(du -sh Products/CopyX.app | cut -f1)"
        
        # 创建快捷方式到桌面（可选）
        read -p "🔗 是否在桌面创建快捷方式？(y/n): " create_shortcut
        if [[ $create_shortcut =~ ^[Yy]$ ]]; then
            ln -sf "$(pwd)/Products/CopyX.app" ~/Desktop/CopyX.app
            echo "✅ 桌面快捷方式已创建"
        fi
        
        # 询问是否立即运行
        read -p "🏃 是否立即运行应用？(y/n): " run_app
        if [[ $run_app =~ ^[Yy]$ ]]; then
            echo "🚀 启动 CopyX..."
            open Products/CopyX.app
        fi
    fi
else
    echo "❌ 构建失败！"
    exit 1
fi

echo "🎉 构建完成！" 