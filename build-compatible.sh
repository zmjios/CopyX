#!/bin/bash

# CopyX 兼容版本构建脚本
# 此脚本将创建一个更兼容的发布版本，移除开发者签名并使用临时签名

echo "🚀 开始构建 CopyX 兼容版本..."
echo "================================"

# 设置变量
APP_NAME="CopyX"
BUILD_DIR="Products"
RELEASE_DATE=$(date +%Y%m%d-%H%M%S)
COMPATIBLE_ZIP="${APP_NAME}-兼容版-$(date +%Y%m%d).zip"

# 检查是否存在构建产物
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo "❌ 错误：找不到 ${BUILD_DIR}/${APP_NAME}.app"
    echo "请先运行 ./build-release.sh 构建应用"
    exit 1
fi

echo "📱 发现应用: ${BUILD_DIR}/${APP_NAME}.app"

# 进入构建目录
cd ${BUILD_DIR}

# 备份原始应用（如果需要）
if [ ! -d "${APP_NAME}-original.app" ]; then
    echo "💾 备份原始应用..."
    cp -R "${APP_NAME}.app" "${APP_NAME}-original.app"
fi

echo "🔓 移除现有签名..."
codesign --remove-signature "${APP_NAME}.app"

if [ $? -eq 0 ]; then
    echo "✅ 原始签名已移除"
else
    echo "⚠️  移除签名时出现警告，继续处理..."
fi

echo "🔐 使用临时签名重新签名..."
codesign --force --deep --sign - "${APP_NAME}.app"

if [ $? -eq 0 ]; then
    echo "✅ 临时签名完成"
else
    echo "❌ 签名失败"
    exit 1
fi

echo "🔍 验证签名状态..."
codesign -dv --verbose=2 "${APP_NAME}.app" 2>&1 | head -5

echo "📄 创建安装说明..."
cat > README.txt << 'EOF'
CopyX 安装说明
===============

如果提示"无法打开CopyX，因为无法验证开发者"：

方法1：系统设置（推荐）
--------------------
1. 双击 CopyX.app（会被阻止）
2. 打开 系统设置 > 隐私与安全性
3. 找到"仍要打开 CopyX"按钮，点击它
4. 再次点击"打开"确认

方法2：终端命令
--------------
打开终端，输入：
sudo spctl --master-disable

然后双击运行 CopyX.app

运行后可以重新启用保护：
sudo spctl --master-enable

方法3：移除隔离属性
------------------
打开终端，输入：
sudo xattr -cr /path/to/CopyX.app

（将路径替换为实际的CopyX.app位置）

---
版本: 1.2.9
这是一个安全的应用程序，已重新签名以提高兼容性。
EOF

echo "📦 创建兼容版本压缩包..."

# 删除旧的兼容版本压缩包
rm -f ${APP_NAME}-兼容版-*.zip

# 创建新的压缩包
zip -r "${COMPATIBLE_ZIP}" "${APP_NAME}.app" README.txt

if [ $? -eq 0 ]; then
    echo "✅ 兼容版本已创建: ${COMPATIBLE_ZIP}"
    
    # 显示文件信息
    echo ""
    echo "📊 文件信息:"
    echo "   - 文件名: ${COMPATIBLE_ZIP}"
    echo "   - 大小: $(du -sh "${COMPATIBLE_ZIP}" | cut -f1)"
    echo "   - 位置: $(pwd)/${COMPATIBLE_ZIP}"
    
    # 显示签名信息
    echo ""
    echo "🔐 签名信息:"
    codesign -dv "${APP_NAME}.app" 2>&1 | grep -E "(Identifier|Signature)"
    
    echo ""
    echo "📝 使用说明:"
    echo "   1. 将 ${COMPATIBLE_ZIP} 分发给用户"
    echo "   2. 用户解压后按 README.txt 说明操作"
    echo "   3. 临时签名版本通常更容易被系统接受"
    
    # 询问是否测试运行
    echo ""
    read -p "🧪 是否测试运行兼容版本？(y/n): " test_run
    if [[ $test_run =~ ^[Yy]$ ]]; then
        echo "🚀 启动兼容版本..."
        open "${APP_NAME}.app"
    fi
    
else
    echo "❌ 创建压缩包失败"
    exit 1
fi

echo ""
echo "🎉 兼容版本构建完成！"
echo "分发文件: ${COMPATIBLE_ZIP}" 