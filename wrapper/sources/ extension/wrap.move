module wrapper::wrap {
    use sui::address;
    use wrapper::wrapper::{Self};

    public struct WRAP has drop {}

    const TOTAL_SUPPLY: u64 = 100000000000000;
    const DECIMALS: u8 = 6;

    const SYMBOL: vector<u8> = b"Wrapper Tokenized Symbol";
    const NAME: vector<u8> = b"Wrapper Tokenized Name";
    const DESCRIPTION: vector<u8> = b"Wrapper Tokenized Description";
    const ICON_URL: vector<u8> = b"https://th.bing.com/th/id/OIP.KIbQVW995sdomP7hAushQgHaHa";


    fun init(otw: WRAP, ctx: &mut TxContext) {
        // wrapper::register<WRAP>(
        //     otw,
        //     DECIMALS,
        //     SYMBOL,
        //     NAME,
        //     DESCRIPTION,
        //     ICON_URL,
        //     address::from_ascii_bytes(&LOCKED_OBJECT),
        //     ctx
        // );
    }
}
