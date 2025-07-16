#!/usr/bin/env ts-node

import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';

/**
 * 🔍 检查测试地址余额和代币状态
 */
async function checkBalances() {
    const client = new SuiClient({ url: getFullnodeUrl('devnet') });
    
    const packageId = '0x8669b49245bad5909dfc9549fb1df5386330869acbcf56c1c37cfcfb808d6ef0';
    const tokenType = `${packageId}::usdt_token::USDT_TOKEN`;
    
    const addresses = [
        '0xb181882764a2cfae461879e032fe05d6ed980a50a26dead8a10f4df26c0bf6af', // 白名单1
        '0x6ea24779ec54ffab9f0ac53495026533a3c06ed37d5c50b2b2ee2589150d74ee', // 白名单2
        '0x76c50b04b686651d268ee4994e6891f7c99e01886a820367e091c24ef996300e', // 非白名单1
    ];
    
    console.log('🔍 检查测试地址余额...');
    console.log('========================');
    
    for (const address of addresses) {
        console.log(`\n📍 地址: ${address.slice(0, 6)}...`);
        
        try {
            // 检查 SUI 余额
            const suiBalance = await client.getBalance({
                owner: address,
                coinType: '0x2::sui::SUI'
            });
            console.log(`💰 SUI 余额: ${parseInt(suiBalance.totalBalance) / 1e9} SUI`);
            
            // 检查 USDT 余额
            const usdtBalance = await client.getBalance({
                owner: address,
                coinType: tokenType
            });
            console.log(`🪙 USDT 余额: ${parseInt(usdtBalance.totalBalance) / 1e6} USDT`);
            
            // 检查代币对象
            const coins = await client.getCoins({
                owner: address,
                coinType: tokenType
            });
            console.log(`📦 USDT 代币对象数量: ${coins.data.length}`);
            
        } catch (error) {
            console.error(`❌ 检查失败: ${error}`);
        }
    }
}

if (require.main === module) {
    checkBalances().catch(console.error);
}
