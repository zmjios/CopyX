#!/bin/bash

# CopyX Release 构建脚本
# 此脚本将编译 Release 版本的应用并将其输出到 Products 文件夹

echo "🚀 开始构建 CopyX Release 版本..."

# 清理之前的构建产物
echo "🧹 清理之前的构建产物..."
rm -rf Products/*

# 构建应用 (Release 配置)
echo "🔨 构建 Release 版本..."
xcodebuild -project CopyX.xcodeproj -scheme CopyX -configuration Release build

if [ $? -eq 0 ]; then
    echo "✅ Release 构建成功！"
    echo "📱 应用位置: $(pwd)/Products/CopyX.app"
    
    # 显示应用信息
    if [ -d "Products/CopyX.app" ]; then
        echo "📊 应用信息:"
        echo "   - 名称: $(defaults read "$(pwd)/Products/CopyX.app/Contents/Info.plist" CFBundleDisplayName 2>/dev/null || echo "CopyX")"
        echo "   - 版本: $(defaults read "$(pwd)/Products/CopyX.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")"
        echo "   - 构建版本: $(defaults read "$(pwd)/Products/CopyX.app/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "Unknown")"
        echo "   - 大小: $(du -sh Products/CopyX.app | cut -f1)"
        echo "   - Bundle ID: $(defaults read "$(pwd)/Products/CopyX.app/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "Unknown")"
        
        # 验证代码签名
        echo "🔐 验证代码签名..."
        codesign -dv --verbose=4 Products/CopyX.app 2>&1 | head -5
        
        # 创建发布包
        echo "📦 创建发布包..."
        RELEASE_DIR="Products/Release-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$RELEASE_DIR"
        cp -R Products/CopyX.app "$RELEASE_DIR/"
        
        # 创建压缩包
        cd Products
        zip -r "CopyX-Release-$(date +%Y%m%d-%H%M%S).zip" CopyX.app
        cd ..
        
        echo "✅ 发布包已创建: $RELEASE_DIR"
        echo "✅ 压缩包已创建: Products/CopyX-Release-*.zip"
        
        # 询问是否立即运行
        read -p "🏃 是否立即运行 Release 版本？(y/n): " run_app
        if [[ $run_app =~ ^[Yy]$ ]]; then
            echo "🚀 启动 CopyX Release 版本..."
            open Products/CopyX.app
        fi
    fi
else
    echo "❌ Release 构建失败！"
    exit 1
fi

echo "🎉 Release 构建完成！" 