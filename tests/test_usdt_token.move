#[test_only]
module usdt_token::test_usdt_token {
    use sui::test_scenario::{Self, next_tx, ctx};
    use sui::coin::{Self, Coin, TreasuryCap};
    use usdt_token::usdt_token::{Self, USDT_TOKEN, TokenConfig};
    use usdt_token::merkle_whitelist;
    use std::vector;

    #[test]
    fun test_init() {
        let admin = @0xA;
        let mut scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        {
            usdt_token::init_for_testing(ctx(scenario));
        };
        
        next_tx(scenario, admin);
        
        {
            // 检查 TokenConfig 是否创建
            assert!(test_scenario::has_most_recent_shared<TokenConfig>(), 0);
            
            // 检查 TreasuryCap 是否转移给管理员
            assert!(test_scenario::has_most_recent_for_sender<TreasuryCap<USDT_TOKEN>>(scenario), 1);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_mint() {
        let admin = @0xA;
        let recipient = @0xB;
        let mut scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        {
            usdt_token::init_for_testing(ctx(scenario));
        };
        
        next_tx(scenario, admin);
        
        {
            let mut config = test_scenario::take_shared<TokenConfig>(scenario);
            let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<USDT_TOKEN>>(scenario);
            
            // 铸造代币
            usdt_token::mint(&mut treasury_cap, &mut config, 1000000, recipient, ctx(scenario));
            
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, treasury_cap);
        };
        
        next_tx(scenario, recipient);
        
        {
            // 检查接收者是否收到代币
            assert!(test_scenario::has_most_recent_for_sender<Coin<USDT_TOKEN>>(scenario), 2);
            
            let mut coin = test_scenario::take_from_sender<Coin<USDT_TOKEN>>(scenario);
            assert!(usdt_token::get_balance(&coin) == 1000000, 3);
            
            test_scenario::return_to_sender(scenario, coin);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_merkle_root() {
        let admin = @0xA;
        let mut scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        {
            usdt_token::init_for_testing(ctx(scenario));
        };
        
        next_tx(scenario, admin);
        
        {
            let mut config = test_scenario::take_shared<TokenConfig>(scenario);
            
            // 创建新的 Merkle Root
            let mut new_root = vector::empty<u8>();
            vector::push_back(&mut new_root, 0x12);
            vector::push_back(&mut new_root, 0x34);
            vector::push_back(&mut new_root, 0x56);
            
            // 更新 Merkle Root
            usdt_token::update_merkle_root(&mut config, new_root, ctx(scenario));
            
            test_scenario::return_shared(config);
        };
        
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_transfer_without_whitelist() {
        let admin = @0xA;
        let user = @0xB;
        let recipient = @0xC;
        let mut scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        
        {
            usdt_token::init_for_testing(ctx(scenario));
        };
        
        next_tx(scenario, admin);
        
        {
            let mut config = test_scenario::take_shared<TokenConfig>(scenario);
            let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<USDT_TOKEN>>(scenario);
            
            // 铸造代币给用户
            usdt_token::mint(&mut treasury_cap, &mut config, 1000000, user, ctx(scenario));
            
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, treasury_cap);
        };
        
        next_tx(scenario, user);
        
        {
            let config = test_scenario::take_shared<TokenConfig>(scenario);
            let coin = test_scenario::take_from_sender<Coin<USDT_TOKEN>>(scenario);
            
            // 尝试转账（应该失败，因为没有在白名单中）
            let empty_proof = vector::empty<vector<u8>>();
            usdt_token::transfer_with_proof(&config, coin, recipient, empty_proof, 0, ctx(scenario));
            
            test_scenario::return_shared(config);
        };
        
        test_scenario::end(scenario_val);
    }
}
