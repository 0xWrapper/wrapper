# wrapper
wrapper protocol


### Wrapper core structure
```move
/// Represents a container for managing a set of objects.
/// Each object is identified by an ID and the Wrapper tracks the type of objects it contains.
/// Fields:
/// - `id`: Unique identifier for the Wrapper.
/// - `kind`: ASCII string representing the type of objects the Wrapper can contain.
/// - `alias`: UTF8 encoded string representing an alias for the Wrapper.
/// - `items`: Vector of IDs or Other Bytes representing the objects wrapped.
/// - `content`: Image or Other Content of the Wrapper.
public struct Wrapper has key, store {
    id: UID,
    kind: std::ascii::String, //type of wrapped object
    alias: std::string::String, // alias for the Wrapper
    items: vector<vector<u8>>, // wrapped object ids
    content: std::string::String, // content url for the Wrapper
}
```

### Kind First
    empty
    inception
    inkscription
    tokenization
    voucherization
    object wrapper type

### Basic operation
- `set_alias(w: &mut Wrapper, alias: std::string::String)`
- `set_content(w: &mut Wrapper, content: std::string::String)`


### inception Wrapper
mint on package init



### inkscription Wrapper
only have items,not children object
as art NFT

- `inkscribe(w: &mut Wrapper, mut ink: vector<std::string::String>)`
- `erase(w: &mut Wrapper, index: u64)`
- `shred(mut w: Wrapper)`

### tokenization Wrapper
any wrapper tokenization

```move
public struct Lock has store {     
    id: ID,
    total_supply: u64,
    owner: Option<address>,
    fund: Balance<SUI>,
}
```

- `tokenized<T: drop>(treasury: TreasuryCap<T>, total_supply: u64, o: ID, mut sui: Coin<SUI>, wrapper: &mut Wrapper, ctx: &mut TxContext)`
- `detokenized<T: drop>(mut wt: Wrapper, ctx: &mut TxContext)` 
- `stocking(wt: &mut Wrapper, sui: Coin<SUI>, ctx: &mut TxContext)`
- `lock<T: drop>(wt: &mut Wrapper, o: Wrapper, ctx: &mut TxContext)`
- `unlock<T: drop>(mut wt: Wrapper, ctx: &mut TxContext)`
- `mint<T: drop>(wt: &mut Wrapper, value: u64, ctx: &mut TxContext)`
- `burn<T: drop>(wt: &mut Wrapper, c: Coin<T>)`

### object wrapper
any object wrapper

- `wrap<T: store + key>(w: &mut Wrapper, mut objects: vector<T>)`
- `unwrap<T: store + key>(mut w: Wrapper, ctx: &mut TxContext)`
- `add<T: store + key>(w: &mut Wrapper, object: T)`
- `shift<T: store + key>(self: &mut Wrapper, w: &mut Wrapper)`
- `remove<T: store + key>(w: &mut Wrapper, i: u64): T`
- `take<T: store + key>(w: &mut Wrapper, id: ID): T`


### voucherization Wrapper/ 
coin locked (SAFT:Simple Agreement for Tokens)

coin  working




### Lsaunchpad & `Wrapper to Earn`

1. Wrappers are free, only gas fees are required.
    Protocol tokens are distributed based on daily wrapping volume, sourced from the monetization of the first wrapper. Token name: wrap.
2. Unwrapping a wrapper requires paying with wrap tokens.
3. 100% community-driven mining.
4. Total supply of 10 billion tokens, with 10 million released daily for 1,000 days, or following a spam curve.
5. If 5 million tokens are produced in less than a day, frenzy mode is activated, releasing the next day's tokens in advance.

### product funtion

Minting and SFT-related functionalities for Object Wrapping

Wrapper Tokenization-related functionalities

Coin Tokenization-related functionalities

Wrapper Exchange (Order Book Model)

Wrapper Mystery Box Game
