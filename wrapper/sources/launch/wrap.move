module wrapper::wrap {
    use sui::coin;
    use sui::url;

    public struct WRAP has drop {}

    #[allow(unused_const)]
    /// The total supply of Sui denominated in whole Sui tokens (10 Billion)
    const TOTAL_SUPPLY: u64 = 18_000_000_000;

    #[allow(unused_const)]
    /// The total supply of Sui denominated in Mist (10 Billion * 10^9)
    const TOTAL_SUPPLY_MIST: u64 = 18_000_000_000_000_000_000;
    const DECIMALS: u8 = 9;

    const SYMBOL: vector<u8> = b"WRAP";
    const NAME: vector<u8> = b"IncentiWrap Wrapper Coin";
    const DESCRIPTION: vector<u8> = b"Incenti Wrapper Coin";
    const ICON_URL: vector<u8> = b"https://th.bing.com/th/id/OIP.KIbQVW995sdomP7hAushQgHaHa";


    fun init(otw: WRAP, ctx: &mut TxContext) {
        let icon_url = if (ICON_URL == b"") {
            option::none()
        } else {
            option::some(url::new_unsafe_from_bytes(ICON_URL))
        };
        // create a new currency
        let (treasury, metadata) = coin::create_currency(otw, DECIMALS, SYMBOL, NAME, DESCRIPTION, icon_url, ctx);
        transfer::public_freeze_object(metadata);
        // transfer to inception object
        transfer::public_transfer(treasury, ctx.sender());
    }
    //
    // public entry fun register<T: drop>(
    //     witness: T,
    //     decimals: u8,
    //     symbol: vector<u8>,
    //     name: vector<u8>,
    //     description: vector<u8>,
    //     icon_url: vector<u8>,
    //     object: address,
    //     ctx: &mut TxContext
    // ) {
    //     // check tokenized object is equal to witness type name
    //     check_tokenized_object<T>(object);
    //     let icon_url = if (icon_url == b"") {
    //         option::none()
    //     } else {
    //         option::some(url::new_unsafe_from_bytes(icon_url))
    //     };
    //     // create a new currency
    //     let (treasury, metadata) = coin::create_currency(witness, decimals, symbol, name, description, icon_url, ctx);
    //     transfer::public_freeze_object(metadata);
    //
    //     // share the tokenized object wrapper with the treasury
    //     tokenized<T>(treasury, object, ctx);
    // }
}
