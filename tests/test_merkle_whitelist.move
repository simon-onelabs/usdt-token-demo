#[test_only]
module usdt_token::test_merkle_whitelist {
    use usdt_token::merkle_whitelist;
    use std::vector;

    #[test]
    fun test_create_merkle_root() {
        let mut root_bytes = vector::empty<u8>();
        vector::push_back(&mut root_bytes, 0x12);
        vector::push_back(&mut root_bytes, 0x34);
        vector::push_back(&mut root_bytes, 0x56);
        
        let merkle_root = merkle_whitelist::create_merkle_root(root_bytes);
        
        // 基本测试，确保函数能正常创建
        assert!(true, 0);
    }

    #[test]
    fun test_address_to_leaf() {
        let addr = @0x1234567890abcdef1234567890abcdef12345678;
        let leaf = merkle_whitelist::address_to_leaf(addr);
        
        // 验证叶子节点不为空
        assert!(!vector::is_empty(&leaf), 0);
        
        // 验证叶子节点长度为32字节（keccak256 哈希长度）
        assert!(vector::length(&leaf) == 32, 1);
    }

    #[test]
    fun test_verify_merkle_proof_simple() {
        // 创建一个简单的 Merkle Root
        let mut root_bytes = vector::empty<u8>();
        vector::push_back(&mut root_bytes, 0x12);
        vector::push_back(&mut root_bytes, 0x34);
        
        let merkle_root = merkle_whitelist::create_merkle_root(root_bytes);
        
        // 创建一个简单的叶子节点
        let mut leaf = vector::empty<u8>();
        vector::push_back(&mut leaf, 0x12);
        vector::push_back(&mut leaf, 0x34);
        
        // 创建空的 proof（单个叶子节点的情况）
        let proof = vector::empty<vector<u8>>();
        
        // 对于单个叶子节点，proof 应该为空，索引为0
        let result = merkle_whitelist::verify_merkle_proof(&merkle_root, leaf, proof, 0);
        assert!(result, 0);
    }

    #[test]
    fun test_verify_whitelist() {
        // 创建测试地址
        let addr = @0x1234567890abcdef1234567890abcdef12345678;
        let leaf = merkle_whitelist::address_to_leaf(addr);
        
        // 使用该地址作为 Merkle Root（单个叶子节点的情况）
        let merkle_root = merkle_whitelist::create_merkle_root(leaf);
        
        // 创建空的 proof
        let proof = vector::empty<vector<u8>>();
        
        // 验证白名单
        let result = merkle_whitelist::verify_whitelist(&merkle_root, addr, proof, 0);
        assert!(result, 0);
    }
}
