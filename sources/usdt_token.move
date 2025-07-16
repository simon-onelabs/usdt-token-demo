module usdt_token::usdt_token {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::event;
    use usdt_token::merkle_whitelist::{Self, MerkleRoot};

    /// 错误码
    const EInsufficientBalance: u64 = 0;
    const ENotInWhitelist: u64 = 1;
    const EInvalidAmount: u64 = 2;

    /// Token 结构体
    public struct USDT_TOKEN has drop {}

    /// Token 配置
    public struct TokenConfig has key {
        id: UID,
        merkle_root: MerkleRoot,
        total_supply: u64,
        decimals: u8,
    }

    /// 转账事件
    public struct TransferEvent has copy, drop {
        from: address,
        to: address,
        amount: u64,
    }

    /// 铸造事件
    public struct MintEvent has copy, drop {
        to: address,
        amount: u64,
    }

    /// 初始化函数
    fun init(witness: USDT_TOKEN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<USDT_TOKEN>(
            witness,
            6, // decimals
            b"USDT",
            b"Tether USD",
            b"A stablecoin pegged to USD with whitelist functionality",
            option::none(),
            ctx
        );

        // 创建默认的 Merkle Root (空白名单)
        let empty_root = vector::empty<u8>();
        let merkle_root = merkle_whitelist::create_merkle_root(empty_root);

        let config = TokenConfig {
            id: object::new(ctx),
            merkle_root,
            total_supply: 0,
            decimals: 6,
        };

        transfer::share_object(config);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(metadata);
    }

    /// 更新 Merkle Root (只有管理员可以调用)
    public entry fun update_merkle_root(
        config: &mut TokenConfig,
        new_root: vector<u8>,
        _ctx: &mut TxContext
    ) {
        config.merkle_root = merkle_whitelist::create_merkle_root(new_root);
    }

    /// 铸造代币
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<USDT_TOKEN>,
        config: &mut TokenConfig,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, EInvalidAmount);
        
        let coin = coin::mint(treasury_cap, amount, ctx);
        config.total_supply = config.total_supply + amount;
        
        transfer::public_transfer(coin, recipient);
        
        event::emit(MintEvent {
            to: recipient,
            amount,
        });
    }

    /// 转账函数 - 需要 Merkle proof 验证
    public entry fun transfer_with_proof(
        config: &TokenConfig,
        coin: Coin<USDT_TOKEN>,
        recipient: address,
        proof: vector<vector<u8>>,
        index: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let amount = coin::value(&coin);
        
        // 验证发送者是否在白名单中
        assert!(
            merkle_whitelist::verify_whitelist(&config.merkle_root, sender, proof, index),
            ENotInWhitelist
        );
        
        transfer::public_transfer(coin, recipient);
        
        event::emit(TransferEvent {
            from: sender,
            to: recipient,
            amount,
        });
    }

    /// 分割代币并转账
    public entry fun split_and_transfer_with_proof(
        config: &TokenConfig,
        coin: &mut Coin<USDT_TOKEN>,
        amount: u64,
        recipient: address,
        proof: vector<vector<u8>>,
        index: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        
        // 验证发送者是否在白名单中
        assert!(
            merkle_whitelist::verify_whitelist(&config.merkle_root, sender, proof, index),
            ENotInWhitelist
        );
        
        assert!(coin::value(coin) >= amount, EInsufficientBalance);
        assert!(amount > 0, EInvalidAmount);
        
        let split_coin = coin::split(coin, amount, ctx);
        transfer::public_transfer(split_coin, recipient);
        
        event::emit(TransferEvent {
            from: sender,
            to: recipient,
            amount,
        });
    }

    /// 获取代币余额
    public fun get_balance(coin: &Coin<USDT_TOKEN>): u64 {
        coin::value(coin)
    }

    /// 获取总供应量
    public fun get_total_supply(config: &TokenConfig): u64 {
        config.total_supply
    }

    /// 获取小数位数
    public fun get_decimals(config: &TokenConfig): u8 {
        config.decimals
    }

    /// 合并代币
    public entry fun join(
        coin1: &mut Coin<USDT_TOKEN>,
        coin2: Coin<USDT_TOKEN>
    ) {
        coin::join(coin1, coin2);
    }

    /// 销毁零价值代币
    public entry fun destroy_zero(coin: Coin<USDT_TOKEN>) {
        coin::destroy_zero(coin);
    }

    // 测试函数
    #[test_only]
    use sui::test_scenario;
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USDT_TOKEN {}, ctx);
    }
}
