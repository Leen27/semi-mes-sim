#!/bin/bash
set -e

echo "🚀 Semi-MES-Sim 初始化脚本"
echo "============================"

# 1. 检查 Node.js 版本
echo "📋 检查 Node.js 版本..."
NODE_VERSION=$(node -v | sed 's/v//')
REQUIRED_VERSION="18.0.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Node.js 版本过低。需要 >= 18.0.0，当前: $NODE_VERSION"
    exit 1
fi
echo "✅ Node.js 版本: $NODE_VERSION"

# 2. 检查并安装 pnpm
echo "📦 检查 pnpm..."
if ! command -v pnpm &> /dev/null; then
    echo "pnpm 未安装，正在安装..."
    npm install -g pnpm@9.0.0
fi
PNPM_VERSION=$(pnpm -v)
echo "✅ pnpm 版本: $PNPM_VERSION"

# 3. 安装依赖
echo "📦 安装依赖..."
pnpm install

# 4. 类型检查
echo "🔍 运行类型检查..."
pnpm type-check

# 5. 运行 Lint
echo "🔍 运行代码检查..."
pnpm lint

# 6. 运行测试
echo "🧪 运行测试..."
pnpm test

# 7. 启动开发服务器
echo "🎉 初始化完成！启动开发服务器..."
echo "=========================================="
echo ""
echo "  访问 http://localhost:5173 查看应用"
echo ""
echo "=========================================="
pnpm dev
