.PHONY: setup dev build test lint type-check check clean init help

# 默认目标
help:
	@echo "Semi-MES-Sim 标准化命令"
	@echo "========================"
	@echo "  setup      - 安装依赖（pnpm install）"
	@echo "  dev        - 启动开发服务器"
	@echo "  build      - 全量构建"
	@echo "  test       - 运行所有测试"
	@echo "  lint       - 代码风格检查"
	@echo "  type-check - TypeScript 类型检查"
	@echo "  check      - 运行 lint + type-check + test（CI 用）"
	@echo "  clean      - 清理构建产物和依赖"
	@echo "  init       - 一键初始化（含检查、安装、验证、启动）"

setup:
	pnpm install

dev:
	pnpm dev

build:
	pnpm build

test:
	pnpm test

lint:
	pnpm lint

type-check:
	pnpm type-check

check: lint type-check test
	@echo "✅ 全部检查通过"

clean:
	pnpm clean

init:
	bash init.sh
