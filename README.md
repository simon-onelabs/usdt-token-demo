# Sui Token Demo

一个基于 Sui 链的 USDT 代币DEMO，集成了 Merkle Tree 白名单验证功能。

## 🚀 功能特性

- ✅ **完整的代币功能**: 基于 Sui Coin 标准的 USDT 代币实现
- ✅ **Merkle Tree 白名单**: 使用 Merkle Tree 进行高效的白名单验证
- ✅ **转账控制**: 只有白名单地址才能进行代币转账
- ✅ **动态白名单**: 支持动态更新 Merkle Root
- ✅ **完整测试**: 包含单元测试和集成测试

## 📁 项目结构

```
sui-token-demo/
├── sources/
│   ├── usdt_token.move          # 主要的 USDT 代币合约
│   └── merkle_whitelist.move    # Merkle Tree 白名单验证模块
├── scripts/                     # 部署和工具脚本
├── tests/                       # 单元测试和集成测试
├── 部署与测试文档.md             # 📖 完整的部署和测试指南
└── Move.toml                    # Move 项目配置
```

## 📋 已部署合约信息

**网络**: Sui Devnet
- **Package ID**: [0xab93dcf01d5ab66e17cc46b654c4727c232e7b18cb189d8ec66645e8e0915c26](https://suiscan.xyz/devnet/object/0xab93dcf01d5ab66e17cc46b654c4727c232e7b18cb189d8ec66645e8e0915c26/tx-blocks)
- **TokenConfig**: [0x49999a2b85c7fb6e6b8ab2b2238f30095d5d0dfff8f5e5d7d3718e1896bd865b](https://suiscan.xyz/devnet/object/0x49999a2b85c7fb6e6b8ab2b2238f30095d5d0dfff8f5e5d7d3718e1896bd865b/tx-blocks)
- **TreasuryCap**: [0x8c7a59997246830701334f7d23a0aae0268eb3e99ae34e8addae3f5f60fe43e6](https://suiscan.xyz/devnet/object/0x8c7a59997246830701334f7d23a0aae0268eb3e99ae34e8addae3f5f60fe43e6/tx-blocks)

## 🧪 测试状态

- **单元测试**: 8/8 通过 ✅
- **集成测试**: 白名单功能验证通过 ✅
- **功能验证**: 转账控制和证明验证正常 ✅

## 详细文档

- [部署与测试文档.md](./部署与测试文档.md) - 完整的部署步骤和测试指南
- [Sui 官方文档](https://docs.sui.io/) - Sui 区块链开发文档
- [Move 编程语言](https://move-language.github.io/move/) - Move 语言参考

## 📄 许可证

MIT License
