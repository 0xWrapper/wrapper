/// Module: template
module tokenization::template {
    use sui::coin;
    use sui::url;
    use sui::transfer::{public_transfer, public_freeze_object};

    public struct TEMPLATE has drop {}

    const LOCKED_OBJECT: vector<u8> = b"6ee7597e7344c205d78979d8052dfae85b2ae01bee40a0abb287d33cdcacc204";
    const TOTAL_SUPPLY: u64 = 100000000000000;
    const DECIMALS: u8 = 6;

    const SYMBOL: vector<u8> = b"Wrapper Tokenized Symbol";
    const NAME: vector<u8> = b"Wrapper Tokenized Name";
    const DESCRIPTION: vector<u8> = b"Wrapper Tokenized Description";
    const ICON_URL: vector<u8> = b"https://th.bing.com/th/id/OIP.KIbQVW995sdomP7hAushQgHaHa";


    fun init(otw: TEMPLATE, ctx: &mut TxContext) {
        // TEMPLATE Coin
        let (treasury, metadata) = coin::create_currency(
            otw,
            DECIMALS,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::some(url::new_unsafe_from_bytes(ICON_URL)),
            ctx
        );
        public_freeze_object(metadata);
        public_transfer(treasury, ctx.sender());
    }
}
