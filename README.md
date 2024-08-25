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
    kind: std::ascii::String,
    //type of wrapped object
    alias: std::string::String,
    // alias for the Wrapper
    items: vector<vector<u8>>,
    // wrapped object ids
    content: std::string::String,
    // content url for the Wrapper
}
```