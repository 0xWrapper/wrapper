module wrapper::vault {

    use std::ascii;
    use sui::coin;
    use sui::coin::Coin;
    use sui::transfer::Receiving;
    use wrapper::wrapper::{Wrapper, exists_field, mutate_field, remove_item, remove_field, exists_object};

    // ====== Vault Error Codes =====
    const EWrapperAcquireAllowedEmptyOrVault: u64 = 0;
    const EWrapperReceiptsAllowedEmptyOrVault: u64 = 1;
    const EWrapperExtractAllowedEmptyOrVault: u64 = 2;
    const EWrapperRetrieveAllowedEmptyOrVault: u64 = 3;
    const EAssetNotFoundInVault: u64 = 4;
    const ECurrencyNotFoundInVault: u64 = 5;
    const ECurrencyNotEnoughAmountInVault: u64 = 6;

    // ===== Wrapper Kind Constants =====
    const VAULT_WRAPPER_KIND: vector<u8> = b"VAULT WRAPPER";

    // =============== Account Extension Functions ===============

    /// Checks if the given Wrapper is a Vault.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - A boolean indicating whether the Wrapper is a Vault.
    public fun is_vault(w: &Wrapper): bool {
        w.kind() == std::ascii::string(VAULT_WRAPPER_KIND)
    }

    public struct CurrencyVault<phantom T> has copy, drop, store {}

    public struct AssetVault<phantom T> has copy, drop, store { id: ID }

    /// Acquires an asset and stores it in the Vault.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `assert`: The asset to be acquired and stored.
    public entry fun acquire<T: key + store>(w: &mut Wrapper, assert: Receiving<T>) {
        assert!(w.is_empty() || is_vault(w), EWrapperAcquireAllowedEmptyOrVault);
        let sent_assert = w.accept(assert);
        if (w.is_empty()) {
            w.set_kind(ascii::string(VAULT_WRAPPER_KIND));
        };
        let assert_id = object::id(&sent_assert);
        let assert_type = AssetVault<T> { id: assert_id };
        w.add_item(assert_id.id_to_bytes());
        w.add_object(assert_type, sent_assert);
    }

    /// Receives a currency and updates the balance in the Vault.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `currency`: The currency to be received and stored.
    public entry fun receipts<T>(w: &mut Wrapper, currency: Receiving<Coin<T>>) {
        assert!(w.is_empty() || is_vault(w), EWrapperReceiptsAllowedEmptyOrVault);
        let coin = w.accept(currency);
        if (w.is_empty()) {
            w.set_kind(ascii::string(VAULT_WRAPPER_KIND));
        };
        let balance_type = CurrencyVault<T> {};
        if (w.exists_field<CurrencyVault<T>, Coin<T>>(balance_type)) {
            let balance: &mut Coin<T> = w.mutate_field(balance_type);
            coin::join(balance, coin);
        } else {
            w.add_item(object::id(&coin).id_to_bytes());
            w.add_field(balance_type, coin);
        }
    }

    /// Extracts an asset from the Vault and transfers it to the requester.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `asset_id`: The ID of the asset to be extracted.
    /// - `ctx`: The transaction context.
    public entry fun extract<T: key + store>(w: &mut Wrapper, asset_id: ID, ctx: &mut TxContext) {
        assert!(w.is_empty() || is_vault(w), EWrapperExtractAllowedEmptyOrVault);
        assert!(vector::contains(&w.items(), &asset_id.id_to_bytes()), EAssetNotFoundInVault);

        let asset_type = AssetVault<T> { id: asset_id };
        assert!(exists_object<AssetVault<T>, T>(w, asset_type), EAssetNotFoundInVault);

        let asset = w.remove_object<AssetVault<T>, T>(asset_type);
        transfer::public_transfer(asset, ctx.sender());
        let (_, index) = vector::index_of(&w.items(), &asset_id.id_to_bytes());
        w.remove_item(index);
    }

    /// Retrieves a specified amount of currency from the Vault and transfers it to the requester.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `amount`: The amount of currency to be retrieved.
    /// - `ctx`: The transaction context.
    public entry fun retrieve<T: key + store>(w: &mut Wrapper, amount: u64, ctx: &mut TxContext) {
        assert!(w.is_empty() || is_vault(w), EWrapperRetrieveAllowedEmptyOrVault);

        let balance_type = CurrencyVault<T> {};
        assert!(exists_field<CurrencyVault<T>, Coin<T>>(w, balance_type), ECurrencyNotFoundInVault);

        let balance: &mut Coin<T> = mutate_field<CurrencyVault<T>, Coin<T>>(w, balance_type);
        assert!(coin::value(balance) >= amount, ECurrencyNotEnoughAmountInVault);

        let coin_to_retrieve = coin::split(balance, amount, ctx);
        if (coin::value(balance) == 0) {
            let currency = remove_field<CurrencyVault<T>, Coin<T>>(w, balance_type);
            let (has, index) = vector::index_of(&w.items(), &object::id(&currency).id_to_bytes());
            assert!(has, ECurrencyNotFoundInVault);
            remove_item(w, index);
            coin::destroy_zero(currency);
        };
        transfer::public_transfer(coin_to_retrieve, ctx.sender());
    }
}
