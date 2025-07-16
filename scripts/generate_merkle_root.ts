#!/usr/bin/env ts-node
/**
 * 🌳 Merkle Root 生成脚本
 * 
 * 功能：
 * 1. 为白名单地址生成 Merkle Root
 * 2. 生成每个地址的 Merkle 证明
 * 3. 输出可用于 Sui CLI 的参数格式
 * 
 * 使用方法：
 * npx ts-node scripts/generate_merkle_root.ts
 */

import { blake2b } from '@noble/hashes/blake2b';
import { MerkleTree } from 'merkletreejs';
import * as fs from 'fs';

// 🔧 配置：在这里添加或修改白名单地址
const WHITELIST_ADDRESSES = [
    '0xb181882764a2cfae461879e032fe05d6ed980a50a26dead8a10f4df26c0bf6af',
    '0x6ea24779ec54ffab9f0ac53495026533a3c06ed37d5c50b2b2ee2589150d74ee',
    // 添加更多地址...
    // '0x新地址1',
    // '0x新地址2',
];

// 🔧 合约配置
const CONTRACT_INFO = {
    packageId: '0xab93dcf01d5ab66e17cc46b654c4727c232e7b18cb189d8ec66645e8e0915c26',
    tokenConfig: '0x49999a2b85c7fb6e6b8ab2b2238f30095d5d0dfff8f5e5d7d3718e1896bd865b',
};

/**
 * 生成地址的叶子节点哈希 - 模拟 Move 代码中的 address_to_leaf 函数
 */
function generateLeafHash(address: string): Buffer {
    // 移除 0x 前缀
    const addressHex = address.startsWith('0x') ? address.slice(2) : address;
    
    // 创建32字节的地址数组（Sui 地址格式）
    const addressBytes = new Uint8Array(32);
    const hexBytes = Buffer.from(addressHex, 'hex');
    addressBytes.set(hexBytes);
    
    // 模拟 BCS 序列化：地址在 BCS 中就是32字节的原始数据
    // 然后用 blake2b 哈希
    return Buffer.from(blake2b(addressBytes, { dkLen: 32 }));
}

/**
 * 生成 Merkle Tree 和相关信息
 */
function generateMerkleTree() {
    console.log('🌳 生成 Merkle Tree');
    console.log('==================================================');
    
    // 1. 生成叶子节点
    const leaves = WHITELIST_ADDRESSES.map(generateLeafHash);
    
    console.log(`📝 白名单地址 (${WHITELIST_ADDRESSES.length} 个):`);
    WHITELIST_ADDRESSES.forEach((addr, i) => {
        console.log(`   ${i + 1}. ${addr}`);
    });
    
    // 2. 创建 Merkle Tree
    const tree = new MerkleTree(
        leaves, 
        (data: Buffer) => Buffer.from(blake2b(data, { dkLen: 32 })), 
        { sortPairs: false }
    );
    
    const root = tree.getRoot();
    console.log(`\n🌳 Merkle Root: 0x${root.toString('hex')}`);
    
    // 3. 生成每个地址的证明
    console.log('\n🔍 Merkle 证明:');
    const proofs: Array<{
        address: string;
        index: number;
        proof: string[];
        leafHash: string;
    }> = [];
    
    WHITELIST_ADDRESSES.forEach((address, index) => {
        const leaf = leaves[index];
        const proof = tree.getProof(leaf);
        const proofHex = proof.map(p => `0x${p.data.toString('hex')}`);
        
        proofs.push({
            address,
            index,
            proof: proofHex,
            leafHash: `0x${leaf.toString('hex')}`
        });
        
        console.log(`   地址 ${index + 1}: ${address}`);
        console.log(`   索引: ${index}`);
        console.log(`   叶子哈希: 0x${leaf.toString('hex')}`);
        console.log(`   证明: [${proofHex.join(', ')}]`);
        console.log('');
    });
    
    return {
        root: `0x${root.toString('hex')}`,
        proofs,
        totalAddresses: WHITELIST_ADDRESSES.length
    };
}

/**
 * 生成 Sui CLI 命令
 */
function generateSuiCommands(merkleData: any) {
    console.log('🔧 Sui CLI 命令');
    console.log('==================================================');
    
    // 1. 更新 Merkle Root 命令
    const rootBytes = merkleData.root.slice(2); // 去掉 0x
    const rootByteArray = [];
    for (let i = 0; i < rootBytes.length; i += 2) {
        rootByteArray.push(parseInt(rootBytes.substr(i, 2), 16));
    }
    
    console.log('📋 1. 更新 Merkle Root:');
    console.log(`sui client call --package ${CONTRACT_INFO.packageId} --module usdt_token --function update_merkle_root --args ${CONTRACT_INFO.tokenConfig} '[${rootByteArray.join(',')}]' --gas-budget 10000000`);
    
    // 2. 铸造代币命令示例
    console.log('\n📋 2. 铸造代币 (示例):');
    console.log(`# 为白名单地址铸造 1000 个代币:`);
    merkleData.proofs.slice(0, 2).forEach((proof: any, i: number) => {
        console.log(`sui client call --package ${CONTRACT_INFO.packageId} --module usdt_token --function mint --args <TREASURY_CAP> ${CONTRACT_INFO.tokenConfig} 1000 ${proof.address} --gas-budget 10000000`);
    });
    
    // 3. 转账命令示例
    console.log('\n📋 3. 白名单转账 (示例):');
    console.log(`# 使用白名单地址转账 (需要切换到对应的地址进行签名):`);
    if (merkleData.proofs.length >= 2) {
        const proof = merkleData.proofs[0];
        const proofArray = proof.proof.map((p: string) => {
            const hex = p.slice(2);
            const bytes = [];
            for (let i = 0; i < hex.length; i += 2) {
                bytes.push(parseInt(hex.substr(i, 2), 16));
            }
            return `[${bytes.join(',')}]`;
        });
        
        console.log(`# 1. 首先切换到白名单地址 (需要私钥):`);
        console.log(`#    sui client switch --address ${proof.address}`);
        console.log(`# 2. 然后执行转账:`);
        console.log(`sui client call --package ${CONTRACT_INFO.packageId} --module usdt_token --function transfer_with_proof --args ${CONTRACT_INFO.tokenConfig} <TOKEN_OBJECT_ID> ${merkleData.proofs[1].address} '[${proofArray.join(',')}]' ${proof.index} --gas-budget 10000000`);
        console.log(`# 注意: <TOKEN_OBJECT_ID> 需要替换为实际的代币对象ID`);
    }
}

/**
 * 保存结果到文件
 */
function saveResults(merkleData: any) {
    const output = {
        timestamp: new Date().toISOString(),
        merkleRoot: merkleData.root,
        totalAddresses: merkleData.totalAddresses,
        addresses: WHITELIST_ADDRESSES,
        proofs: merkleData.proofs,
        contractInfo: CONTRACT_INFO
    };
    
    const filename = `merkle_data_${new Date().toISOString().slice(0, 10)}.json`;
    fs.writeFileSync(filename, JSON.stringify(output, null, 2));
    console.log(`\n💾 结果已保存到: ${filename}`);
}

/**
 * 主函数
 */
function main() {
    console.log('🚀 Merkle Root 生成器');
    console.log('==================================================');
    console.log(`📅 生成时间: ${new Date().toLocaleString()}`);
    console.log(`📦 Package ID: ${CONTRACT_INFO.packageId}`);
    console.log(`🔧 Token Config: ${CONTRACT_INFO.tokenConfig}`);
    console.log('');
    
    try {
        // 生成 Merkle Tree
        const merkleData = generateMerkleTree();
        
        // 生成 Sui CLI 命令
        generateSuiCommands(merkleData);
        
        // 保存结果
        saveResults(merkleData);
        
        console.log('\n✅ Merkle Root 生成完成！');
        console.log('');
        console.log('📋 使用说明:');
        console.log('1. 复制上面的 "更新 Merkle Root" 命令并执行');
        console.log('2. 使用 "铸造代币" 命令为白名单地址铸造代币');
        console.log('3. 使用 "白名单转账" 命令测试转账功能 (需要切换到对应地址签名)');
        console.log('4. 要添加新地址，请编辑脚本开头的 WHITELIST_ADDRESSES 数组');
        console.log('');
        console.log('📝 重要提醒:');
        console.log('- 铸造代币时使用部署者地址 (拥有 TreasuryCap)');
        console.log('- 转账时需要切换到代币所有者地址进行签名');
        console.log('- 替换 <TREASURY_CAP> 为实际的 TreasuryCap 对象ID');
        console.log('- 替换 <TOKEN_OBJECT_ID> 为实际的代币对象ID');
        
    } catch (error) {
        console.error('❌ 生成失败:', error);
    }
}

// 运行主函数
main();
