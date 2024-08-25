module wrapper::wrap {
    use sui::coin;
    use sui::coin::TreasuryCap;
    use sui::url;

    // ===== Coin =====
    #[allow(unused_const)]
    const TOTAL_SUPPLY_WRAPPER_COIN: u64 = 10_000_000_000;

    #[allow(unused_const)]
    const MIST_PER_WRAPPER: u64 = 1_000_000;

    #[allow(unused_const)]
    const TOTAL_SUPPLY_MIST_WRAPPER_COIN: u64 = 10_000_000_000_000_000;

    const WRAPPER_COIN_DECIMALS: u8 = 6;
    const WRAPPER_COIN_SYMBOL: vector<u8> = b"WRAPPER";
    const WRAPPER_COIN_NAME: vector<u8> = b"WRAPPER";
    const WRAPPER_COIN_DESCRIPTION: vector<u8> = b"Wrapper incentive coin";
    const WRAPPER_COIN_ICON_URL: vector<u8> = b"https://th.bing.com/th/id/OIP.KIbQVW995sdomP7hAushQgHaHa";

    public fun coin_mist(): u64 {
        return MIST_PER_WRAPPER
    }

    public fun total_supply_mist(): u64 {
        return TOTAL_SUPPLY_MIST_WRAPPER_COIN
    }

    public fun total_supply(): u64 {
        return TOTAL_SUPPLY_WRAPPER_COIN
    }

    public fun decimals(): u8 {
        return WRAPPER_COIN_DECIMALS
    }

    /// A one-time witness object used for claiming packages and transferring ownership within the Sui framework.
    /// This object is used to initialize and setup the display and ownership of newly created Wrappers.
    public struct WRAP has drop {}

    /// init a WRAP coin ,when publish to network
    /// use for future protocol governance
    fun init(witness: WRAP, ctx: &mut TxContext) {
        let treasury = init_coin(witness, ctx);
        transfer::public_transfer(treasury, ctx.sender());
    }

    #[lint_allow(self_transfer)]
    /// function to assists in creating various tokens in the wrapper protocol
    public(package) fun init_coin<T: drop>(witness: T, ctx: &mut TxContext): TreasuryCap<T> {
        let (treasury, metadata) = coin::create_currency(
            witness,
            WRAPPER_COIN_DECIMALS,
            WRAPPER_COIN_SYMBOL,
            WRAPPER_COIN_NAME,
            WRAPPER_COIN_DESCRIPTION,
            option::some(url::new_unsafe_from_bytes(WRAPPER_COIN_ICON_URL)),
            ctx
        );

        transfer::public_transfer(metadata, ctx.sender());
        treasury
    }
}
