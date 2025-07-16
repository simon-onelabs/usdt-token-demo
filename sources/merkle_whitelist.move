module usdt_token::merkle_whitelist {
    use sui::hash;
    use sui::bcs;

    /// Merkle Tree 根节点结构
    public struct MerkleRoot has copy, drop, store {
        root: vector<u8>,
    }

    /// 创建 Merkle Root
    public fun create_merkle_root(root: vector<u8>): MerkleRoot {
        MerkleRoot { root }
    }

    /// 验证 Merkle proof
    public fun verify_merkle_proof(
        merkle_root: &MerkleRoot,
        leaf: vector<u8>,
        proof: vector<vector<u8>>,
        index: u64
    ): bool {
        let mut computed_hash = leaf;
        let mut path = index;
        let mut i = 0;
        let proof_len = vector::length(&proof);
        
        while (i < proof_len) {
            let proof_element = *vector::borrow(&proof, i);
            
            if (path % 2 == 0) {
                // 左节点
                let mut combined = vector::empty<u8>();
                vector::append(&mut combined, computed_hash);
                vector::append(&mut combined, proof_element);
                computed_hash = hash::blake2b256(&combined);
            } else {
                // 右节点
                let mut combined = vector::empty<u8>();
                vector::append(&mut combined, proof_element);
                vector::append(&mut combined, computed_hash);
                computed_hash = hash::blake2b256(&combined);
            };
            
            path = path / 2;
            i = i + 1;
        };
        
        computed_hash == merkle_root.root
    }

    /// 将地址转换为叶子节点
    public fun address_to_leaf(addr: address): vector<u8> {
        let addr_bytes = bcs::to_bytes(&addr);
        hash::blake2b256(&addr_bytes)
    }

    /// 验证地址是否在白名单中
    public fun verify_whitelist(
        merkle_root: &MerkleRoot,
        addr: address,
        proof: vector<vector<u8>>,
        index: u64
    ): bool {
        let leaf = address_to_leaf(addr);
        verify_merkle_proof(merkle_root, leaf, proof, index)
    }
}
