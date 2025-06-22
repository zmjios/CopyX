# CopyX 构建指南

## 📁 Products 文件夹

项目现在包含一个 `Products` 文件夹，用于存放编译后的应用程序。这样您就可以直接在项目根目录找到编译好的 CopyX.app 文件。

## 🛠 构建方式

### 方式一：使用构建脚本（推荐）

#### Debug 版本

```bash
./build.sh
```

#### Release 版本

```bash
./build-release.sh
```

### 方式二：使用 Xcode 命令行

#### Debug 版本

```bash
xcodebuild -project CopyX.xcodeproj -scheme CopyX -configuration Debug build
```

#### Release 版本

```bash
xcodebuild -project CopyX.xcodeproj -scheme CopyX -configuration Release build
```

### 方式三：使用 Xcode IDE

1. 打开 `CopyX.xcodeproj`
2. 选择 CopyX scheme
3. 按 `Cmd+B` 构建
4. 编译完成后，应用会自动输出到 `Products` 文件夹

## 📦 构建产物

构建完成后，您会在 `Products` 文件夹中找到：

- `CopyX.app` - 可执行的应用程序
- `CopyX-Release-*.zip` - Release 版本的压缩包（仅 Release 构建）
- `Release-*` 文件夹 - 带时间戳的发布包（仅 Release 构建）

## 🚀 运行应用

### 直接运行

```bash
open Products/CopyX.app
```

### 或者双击

在 Finder 中双击 `Products/CopyX.app` 即可运行

## 🔧 项目配置

项目已配置以下构建设置：

- `CONFIGURATION_BUILD_DIR = "$(PROJECT_DIR)/Products"`
- 这确保了所有构建产物都输出到项目根目录的 Products 文件夹

## 📋 构建脚本功能

### build.sh (Debug 构建)

- 清理之前的构建产物
- 编译 Debug 版本
- 显示应用信息（名称、版本、大小）
- 可选择创建桌面快捷方式
- 可选择立即运行应用

### build-release.sh (Release 构建)

- 清理之前的构建产物
- 编译 Release 版本
- 显示详细应用信息
- 验证代码签名
- 创建带时间戳的发布包
- 创建压缩包
- 可选择立即运行应用

## 🗂 文件结构

```
CopyX/
├── Products/                 # 构建产物输出目录
│   ├── CopyX.app            # 编译后的应用
│   ├── Release-*/           # Release 发布包
│   └── CopyX-Release-*.zip  # Release 压缩包
├── build.sh                 # Debug 构建脚本
├── build-release.sh         # Release 构建脚本
├── BUILD_GUIDE.md          # 构建指南（本文件）
└── ...                     # 其他项目文件
```

## 💡 提示

1. **首次构建**：第一次构建可能需要更长时间，因为 Xcode 需要下载依赖项
2. **清理构建**：如果遇到构建问题，可以使用 `Product → Clean Build Folder` 或删除 `Products` 文件夹
3. **权限问题**：如果脚本无法执行，请确保已添加执行权限：`chmod +x build.sh build-release.sh`
4. **代码签名**：Release 版本会显示代码签名信息，确保应用可以正常分发

## 🔍 故障排除

如果构建失败，请检查：

1. Xcode 是否已安装且为最新版本
2. 命令行工具是否已安装：`xcode-select --install`
3. 项目依赖是否完整
4. 开发者证书是否有效（Release 构建）
