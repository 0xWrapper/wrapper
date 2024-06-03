/// Module: wrapper
/// Github: https://github.com/0xWrapper/wrapper
/// Provides functionality for managing a collection of objects within a "Wrapper".
/// This module includes functionalities to wrap, unwrap, merge, split, and manage items in a Wrapper.
/// It handles different kinds of objects and ensures that operations are type-safe.
module wrapper::wrapper {
    use std::type_name;
    use sui::dynamic_object_field as dof;
    use sui::dynamic_field as df;
    use sui::display;
    use sui::package;
    use sui::event;
    use sui::balance::{Self,Balance};
    use sui::sui::{SUI};

    // == tokenized ==
    use std::ascii;
    use sui::url::{Self};
    use sui::coin::{Self, Coin, TreasuryCap};


    // ===== Error Codes =====
    const EItemNotFound: u64 = 0;
    const EIndexOutOfBounds: u64 = 1;
    const EItemNotSameKind: u64 = 2;
    const EItemNotFoundOrNotSameKind: u64 = 3;
    const EWrapperNotEmpty: u64 = 4;

    // === InkSciption Error Codes ===
    const EWrapperNotEmptyOrInkSciption: u64 = 5;

    // === TOKENIZED Error Codes ===
    const ENOT_TOKENIZED_WRAPPER: u64 = 6;
    const EWRAPPER_TOKENIZED_MISMATCH: u64 = 7;
    const EWRAPPER_TOKENIZED_NOT_TREASURY: u64 = 8;
    const EWRAPPER_TOKENIZED_NOT_LOCK: u64 = 9;
    const EWRAPPER_TOKENIZED_NOT_TOKENIZED: u64 = 10;
    const EWRAPPER_TOKENIZED_HAS_TOKENIZED: u64 = 11;
    const EWRAPPER_TOKENIZED_NOT_ACCESS: u64 = 12;
    const EWRAPPER_TOKENIZED_HAS_OWNER: u64 = 13;
    const ECANNOT_UNLOCK_NON_ZERO_SUPPLY: u64 = 14;
    const ETOKEN_SUPPLY_MISMATCH: u64 = 15;
    const ENOT_INCEPTION_TOKENIZED_WRAPPER: u64 = 16;
    const EINVALID_SUI_VALUE: u64 = 17;
    const EINSUFFICIENT_BALANCE: u64 = 18;

    // ===== Wrapper Kind Constants =====
    const EMPTY_WRAPPER_KIND: vector<u8> = b"EMPTY WRAPPER";
    const INKSCRIPTION_WRAPPER_KIND: vector<u8> = b"INKSCRIPTION WRAPPER";
    const TOKENIZED_WRAPPER_KIND: vector<u8> = b"TOKENIZATION WRAPPER";
    const INCEPTION_WRAPPER_KIND: vector<u8> = b"INCEPTION WRAPPER";


    const SUI_MIST_PER_SUI: u64 = 1_000_000_000;

    // inception wrapper object id
    const INCEPTION_WRAPPER_OBJECT_ID: address = @0x6;

    // ===== Wrapper Core Struct =====

    /// A one-time witness object used for claiming packages and transferring ownership within the Sui framework.
    /// This object is used to initialize and setup the display and ownership of newly created Wrappers.
    public struct WRAPPER has drop {}

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

    // ===== Inital functions =====

    /// Event emitted when Wrapper Protocal is initialized.
    public struct Init has copy,drop{
        creater: address,
        publisher: ID,
        display: ID,
        inception: ID,
    }

    /// Checks if the Wrapper is inception.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the Wrapper is just create on init, false otherwise.
    public fun is_inception(w: &Wrapper): bool {
        w.kind == std::ascii::string(INCEPTION_WRAPPER_KIND)
    }

    #[lint_allow(self_transfer)]
    /// Initializes a new Wrapper and sets up its display and publisher.
    /// Claims a publisher using the provided WRAPPER object and initializes the display.
    /// Parameters:
    /// - `witness`: A one-time witness object for claiming the package.
    /// - `ctx`: Transaction context for managing blockchain-related operations.
    /// Effect:
    /// - Transfers the ownership of the publisher and display to the transaction sender.
    fun init(witness: WRAPPER, ctx:&mut TxContext){
        let publisher = package::claim(witness,ctx);
        let keys = vector[
            std::string::utf8(b"kind"),
            std::string::utf8(b"alias"),
            std::string::utf8(b"image_url"),
            std::string::utf8(b"project_url"),
        ];
        let values = vector[
            std::string::utf8(b"{kind}"),
            std::string::utf8(b"{alias}"),
            std::string::utf8(b"{content}"),
            std::string::utf8(b"https://wrapper.space"),
        ];
        let mut display = display::new_with_fields<Wrapper>(&publisher,keys,values,ctx);
        display::update_version<Wrapper>(&mut display);
        // Genesis Wrapper
        let w  = inception(ctx);
        event::emit(Init{
                creater: tx_context::sender(ctx),
                publisher: object::id(&publisher),
                display: object::id(&display),
                inception: object::id(&w),
        });

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
        transfer::public_transfer(w, tx_context::sender(ctx));
    }

    /// Creates a new Wrapper with the INKSCRIPTION kind.
    fun inception(ctx: &mut TxContext):Wrapper {
        let mut inception = new(ctx);
        inception.kind = std::ascii::string(b"INCEPTION WRAPPER");
        inception.alias = std::string::utf8(b"The Dawn of Wrapper Protocol");
        inception.content = std::string::utf8(b"https://ipfs.filebase.io/ipfs/QmYZgGG5QSegRZQg8p2MXMkzwdYLu6fWvLDCbFL8fhPNZX");
        
        vector::push_back(&mut inception.items, b"In Genesis, the birth of vision's light,");
        vector::push_back(&mut inception.items, b"Prime movers seek the endless flight.");
        vector::push_back(&mut inception.items, b"Origin of dreams in tokens cast,");
        vector::push_back(&mut inception.items, b"Alpha minds, forging futures vast.");

        vector::push_back(&mut inception.items, b"Pioneers of liquidity's rise,");
        vector::push_back(&mut inception.items, b"Inception's brilliance in our eyes.");
        vector::push_back(&mut inception.items, b"First steps in a realm so grand,");
        vector::push_back(&mut inception.items, b"Proto solutions, deftly planned.");

        vector::push_back(&mut inception.items, b"Founding pillars of trust and trade,");
        vector::push_back(&mut inception.items, b"Eureka moments that never fade.");
        vector::push_back(&mut inception.items, b"In Wrapper's embrace, assets entwine,");
        vector::push_back(&mut inception.items, b"Revolution in every design.");

        vector::push_back(&mut inception.items, b"Smart contracts, decentralized might,");
        vector::push_back(&mut inception.items, b"Liquidity pools, shining bright.");
        vector::push_back(&mut inception.items, b"Tokenization's seamless grace,");
        vector::push_back(&mut inception.items, b"In every swap, a better place.");

        vector::push_back(&mut inception.items, b"Yield and NFTs display,");
        vector::push_back(&mut inception.items, b"In dynamic, flexible sway.");
        vector::push_back(&mut inception.items, b"From blind boxes to swap's exchange,");
        vector::push_back(&mut inception.items, b"In Wrapper's world, nothing's strange.");

        vector::push_back(&mut inception.items, b"In Genesis, we lay the ground,");
        vector::push_back(&mut inception.items, b"Prime visions in Wrapper found.");
        vector::push_back(&mut inception.items, b"With every step, we redefine,");
        vector::push_back(&mut inception.items, b"A future bright, in Wrapper's line.");
        inception
    }

    // ===== Basic Functions =====


    /// Event emitted when Wrapper is created.
    public struct Create has copy,drop{
        creater: address,
        id: ID,
    }

    /// Creates a new, empty Wrapper.
    /// Parameters:
    /// - `ctx`: Transaction context used for creating the Wrapper.
    /// Returns:
    /// - A new Wrapper with no items and a generic kind.
    public fun new(ctx: &mut TxContext): Wrapper {
        let id = object::new(ctx);
        event::emit(Create{
            creater: tx_context::sender(ctx),
            id: id.to_inner(),
        });
        Wrapper {
            id: id,
            kind: std::ascii::string(EMPTY_WRAPPER_KIND),
            alias: std::string::utf8(EMPTY_WRAPPER_KIND),
            items: vector[],
            content: std::string::utf8(b""),
        }
    }

    /// Event emitted when Wrapper is destroy.
    public struct Destroy has copy,drop{
        id: ID,
        kind: std::ascii::String,
    }

    /// Destroys the Wrapper, ensuring it is empty before deletion.
    /// Parameters:
    /// - `w`: The Wrapper to destroy.
    /// Effects:
    /// - The Wrapper and its identifier are deleted.
    /// Errors:
    /// - `EWrapperNotEmpty`: If the Wrapper is not empty at the time of destruction.
    public fun destroy_empty(w: Wrapper) {
        // remove all items from the Wrapper
        assert!(w.is_empty(), EWrapperNotEmpty);
        // delete the Wrapper
        let Wrapper { id, kind: kind, alias:_, items:_,  content:_ } = w;
        event::emit(Destroy{
            id: id.to_inner(),
            kind: kind,
        });
        id.delete();
    }

    // ===== Basic Check functions =====

    /// Checks if the specified type T matches the kind of items stored in the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the type T matches the Wrapper's kind, false otherwise.
    public fun is_same_kind<T: key + store>(w: &Wrapper): bool {
        w.kind == type_name::into_string(type_name::get<T>())
    }

    /// Checks if the Wrapper is empty.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the Wrapper contains no items, false otherwise.
    public fun is_empty(w: &Wrapper): bool {
        w.kind == std::ascii::string(EMPTY_WRAPPER_KIND) || w.count() == 0
    }

    // ===== Basic property functions =====

    /// Retrieves the kind of objects contained within the Wrapper.
    /// Returns an ASCII string representing the type of the wrapped objects.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - ASCII string indicating the kind of objects in the Wrapper.
    public fun kind(w: &Wrapper): std::ascii::String {
        w.kind
    }

    /// Retrieves the alias of the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - UTF8 encoded string representing the alias of the Wrapper.
    public fun alias(w: &Wrapper): std::string::String {
        w.alias
    }

    /// Retrieves all object IDs contained within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - A vector of some items or IDs representing all objects within the Wrapper.
    public fun items(w: &Wrapper): vector<vector<u8>> {
        w.items
    }

    /// Returns the number of objects contained within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - The count of items in the Wrapper as a 64-bit unsigned integer.
    public fun count(w: &Wrapper): u64 {
        w.items.length()
    }

    /// Retrieves the ID of the object at a specified index within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `i`: Index of the item to retrieve.
    /// Returns:
    /// - item or ID of the object at the specified index.
    /// Errors:
    /// - `EIndexOutOfBounds`: If the provided index is out of bounds.
    public fun item(w: &Wrapper, i: u64): vector<u8> {
        if (w.count() <= i) {
            abort EIndexOutOfBounds
        }else{
            w.items[i]
        }
    }

    // ===== Basic Public Entry functions =====

    /// Sets a new alias for the Wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `alias`: New alias to set for the Wrapper.
    /// Effects:
    /// - Updates the alias field of the Wrapper.
    public entry fun set_alias(w: &mut Wrapper, alias: std::string::String) {
        w.alias = alias;
    }

    /// Sets a new content for the Wrapper
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `content`: New content to set for the Wrapper.
    /// Effects:
    /// - Updates the content field of the Wrapper.
    public entry fun set_content(w: &mut Wrapper, content: std::string::String) {
        w.content = content;
    }


    // =============== Ink Extension Functions ===============

    // ===== Ink Check functions =====

    /// Checks if the Wrapper is inkscription.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the Wrapper only contains items, false otherwise.
    public fun is_inkscription(w: &Wrapper): bool {
        w.kind == std::ascii::string(INKSCRIPTION_WRAPPER_KIND)
    }

    // ===== Ink Public Entry functions =====
    
    /// Appends an ink inscription to the Wrapper.
    /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `ink`: The string to be inscribed.
    /// Errors:
    /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is neither empty nor an inscription.
    public entry fun inkscribe(w: &mut Wrapper, mut ink:vector<std::string::String>) {
        assert!(w.is_inkscription() || w.is_empty(), EWrapperNotEmptyOrInkSciption);
        if (w.is_empty()) {
            w.kind = std::ascii::string(INKSCRIPTION_WRAPPER_KIND)
        };
        while (ink.length() > 0){
            vector::push_back(&mut w.items, *ink.pop_back().bytes());
        };
        ink.destroy_empty();
    }

    /// Removes an ink inscription from the Wrapper at a specified index.
    /// Ensures that the operation is type-safe and the index is within bounds.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `index`: Index of the inscription to remove.
    /// Errors:
    /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is not an inscription.
    /// - `EIndexOutOfBounds`: If the index is out of bounds.
    public entry fun erase(w: &mut Wrapper, index: u64) {
        assert!(w.is_inkscription(), EWrapperNotEmptyOrInkSciption);
        assert!(w.count() > index, EIndexOutOfBounds);
        vector::remove(&mut w.items, index);
        if (w.count() == 0) {
            w.kind = std::ascii::string(EMPTY_WRAPPER_KIND)
        };
    }

    /// Shred all ink inscriptions in the Wrapper, effectively clearing it.
    /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
    /// Parameters:
    /// - `w`: The Wrapper to be burned.
    /// Errors:
    /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is neither empty nor an ink inscription.
    public entry fun shred(mut w: Wrapper) {
        assert!(w.is_inkscription() || w.is_empty(), EWrapperNotEmptyOrInkSciption);
        while (w.count() > 0) {
            vector::pop_back(&mut w.items);
        };
        w.destroy_empty()
    }
    

    // =============== Object Extension Functions ===============

    /// Represents a dynamic field key for an item in a Wrapper.
    /// Each item in a Wrapper has a unique identifier of type ID.
    public struct Item has store, copy, drop { id: ID }

    // ===== Object Check functions =====
    
    /// Checks if an item with the specified ID exists within the Wrapper and is of type T.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Returns:
    /// - True if the item exists and is of type T, false otherwise.
    public fun has_item_with_type<T: key + store>(w: &Wrapper, id: ID): bool {
        dof::exists_with_type<Item, T>(&w.id, Item { id }) && w.items.contains(&id.to_bytes()) && w.is_same_kind<T>()
    }

    // ===== Object property functions =====

    #[syntax(index)]
    /// Borrow an immutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `i`: Index of the object to borrow.
    /// Returns:
    /// - Immutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow<T:store + key>(w: &Wrapper,i: u64): &T {
        let id = object::id_from_bytes(w.item(i));
        assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
        dof::borrow(&w.id, Item { id })
    }

    #[syntax(index)]
    /// Borrow a mutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `i`: Index of the object to borrow.
    /// Returns:
    /// - Mutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow_mut<T:store + key>(w: &mut Wrapper, i: u64): &mut T {
        let id = object::id_from_bytes(w.item(i));
        assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
        dof::borrow_mut(&mut w.id, Item { id })
    }


    // ===== Object Public Entry functions =====
    
    /// Wraps object list into a new Wrapper.
    /// Parameters:
    /// - `w`: The Wrapper to unwrap.
    /// - `object`: The object to wrap.
    /// Returns:
    /// - all objects of type T warp the Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If any contained item is not of type T.
    public entry fun wrap<T: store + key>(w:&mut Wrapper, mut objects:vector<T>){
        assert!(w.is_same_kind<T>(), EItemNotSameKind);
        // add the object to the Wrapper
        while (objects.length() > 0){
            w.add(objects.pop_back());
        };
        objects.destroy_empty();
    }

    /// TODO: USE THE INCEPTION WRAPPER TOKENIZED COIN TO UNWRAP
    /// Unwraps all objects from the Wrapper, ensuring all are of type T, then destroys the Wrapper.
    /// Parameters:
    /// - `w`: The Wrapper to unwrap.
    /// Returns:
    /// - Vector of all objects of type T from the Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If any contained item is not of type T.
    public entry fun unwrap<T:store + key>(mut w: Wrapper, ctx: &mut TxContext) {
        assert!(w.is_same_kind<T>(), EItemNotSameKind);
        // unwrap all objects from the Wrapper
        while (w.count() > 0){
            let id = object::id_from_bytes(w.item(0));
            let object:T = dof::remove<Item,T>(&mut w.id, Item { id });
            transfer::public_transfer(object, ctx.sender());
            w.items.swap_remove(0);
        };
        // destroy the Wrapper
        w.destroy_empty();
    }

    /// Adds a single object to the Wrapper. If the Wrapper is empty, sets the kind based on the object's type.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `object`: The object to add to the Wrapper.
    /// Effects:
    /// - The object is added to the Wrapper, and its ID is stored.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrapper is not empty and the object's type does not match the Wrapper's kind.
    public entry fun add<T:store + key>(w: &mut Wrapper, object:T) {
        // check the object's kind
        if (w.kind == std::ascii::string(EMPTY_WRAPPER_KIND)) {
            w.kind = type_name::into_string(type_name::get<T>())
        } else {
            assert!(w.is_same_kind<T>(), EItemNotSameKind)
        };
        // add the object to the Wrapper
        let oid = object::id(&object);
        dof::add(&mut w.id, Item{ id: oid }, object);
        w.items.push_back(oid.to_bytes());
    }

    /// Transfers all objects from one Wrapper (`self`) to another (`w`).
    /// Both Wrappers must contain items of the same type T.
    /// Parameters:
    /// - `self`: Mutable reference to the source Wrapper.
    /// - `w`: Mutable reference to the destination Wrapper.
    /// Effects:
    /// - Objects are moved from the source to the destination Wrapper.
    /// - The source Wrapper is left empty after the operation.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrappers do not contain the same type of items.
    public entry fun shift<T: store + key>(self:&mut Wrapper, w: &mut Wrapper) {
        assert!(self.is_same_kind<T>(), EItemNotSameKind);
        while (self.count() > 0){
            w.add(self.remove<T>(0));
        };
    }

    // ===== Object Internal functions =====
    
    /// Removes an object from the Wrapper at a specified index and returns it.
    /// Checks that the operation is type-safe.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `i`: Index of the item to remove.
    /// Returns:
    /// - The object of type T removed from the Wrapper.
    /// Effects:
    /// - If the Wrapper is empty after removing the item, its kind is set to an empty string.
    /// Errors:
    /// - `EItemNotSameKind`: If the item type does not match the Wrapper's kind.
    public(package) fun remove<T:store + key>(w: &mut Wrapper, i: u64): T {
        assert!(w.count() > i, EIndexOutOfBounds);
        assert!(w.is_same_kind<T>(), EItemNotSameKind);
        // remove the item from the Wrapper
        let id = object::id_from_bytes(w.item(i));
        let object:T = dof::remove<Item,T>(&mut w.id, Item { id });
        w.items.swap_remove(i);
        // if the Wrapper is empty, set the kind to empty
        if (w.count() == 0) {
            w.kind = std::ascii::string(EMPTY_WRAPPER_KIND)
        };
        object
    }

    /// Removes and returns a single object from the Wrapper by its ID.
    /// Ensures the object exists and is of type T.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `id`: ID of the object to remove.
    /// Returns:
    /// - The object of type T.
    /// Errors:
    /// - `EItemNotFound`: If no item with the specified ID exists.
    public(package) fun take<T:store + key>(w: &mut Wrapper, id: ID): T {
        assert!(w.has_item_with_type<T>(id), EItemNotFound);
        // remove the item from the Wrapper
        let (has_item,index) = w.items.index_of(&id.to_bytes());
        if (has_item) {
            w.remove(index)
        }else{
            abort EItemNotFound 
        }
    }

    // ===== Object Public functions =====

    /// Merges two Wrappers into one. If both Wrappers are of the same kind, merges the smaller into the larger.
    /// If they are of different kinds or if one is empty, handles accordingly.
    /// If the two Wrappers have the same kind, merge the less Wrapper into the greater Wrapper.
    /// Otherwise, create a new Wrapper and add the two Wrappers.
    /// If the two Wrappers are empty, return an empty Wrapper.
    /// If one Wrapper is empty, return the other Wrapper.
    /// Parameters:
    /// - `w1`: First Wrapper to merge.
    /// - `w2`: Second Wrapper to merge.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A single merged Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrappers contain different kinds of items and cannot be merged.
    public fun merge<T:store + key>(mut w1: Wrapper, mut w2: Wrapper, ctx: &mut TxContext): Wrapper{
        let kind = type_name::into_string(type_name::get<T>());
        // if one of the Wrappers is empty, return the other Wrapper
        if (w1.is_empty()) {
            w1.destroy_empty();
            w2
        } else if (w2.is_empty()) {
            w2.destroy_empty();
            w1
        } else if (w1.kind == w2.kind && w2.kind == kind) {
            // check the count of the two Wrappers
            if (w1.count() > w2.count()) {
                w2.shift<T>(&mut w1);
                w2.destroy_empty();
                w1
            } else {
                w1.shift<T>(&mut w2);
                w1.destroy_empty();
                w2
            }
        } else {
            // create a new Wrapper
            let mut w = new(ctx);
            w.add(w1);
            w.add(w2);
            w
        }
    }

    /// Splits objects from the Wrapper based on the specified list of IDs, moving them into a new Wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the original Wrapper.
    /// - `ids`: Vector of IDs indicating which items to split.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A new Wrapper containing the split items.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If any specified ID does not exist or the item is not of the expected type.
    public fun split<T:store + key>(w: &mut Wrapper,mut ids: vector<ID>, ctx: &mut TxContext): Wrapper{
        // create a new Wrapper
        let mut w2 = new(ctx);
        // take the objects from the first Wrapper and add them to the second Wrapper
        while (ids.length() > 0){
            assert!(w.has_item_with_type<T>(ids[ids.length()-1]), EItemNotFoundOrNotSameKind);
            w2.add(w.take<T>(ids.pop_back()));
        };
        ids.destroy_empty();
        w2
    }

    // =============== Tokenized Extension Functions ===============

    /// Represents a lock for a tokenized object.
    public struct Lock has store {     
        id: ID,
        total_supply: u64,
        owner: Option<address>,
        fund: Balance<SUI>,
    }

    // === Tokenized Public Check Functions ===

    /// Asserts that the given wrapper is tokenized.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Errors:
    /// - `ENOT_TOKENIZED_WRAPPER`: If the wrapper is not tokenized.
    public fun is_tokenized(w: &Wrapper) {
        assert!(w.kind == std::ascii::string(TOKENIZED_WRAPPER_KIND), ENOT_TOKENIZED_WRAPPER);
    }

    /// Asserts that the given wrapper has the specified wrapper item.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Errors:
    /// - `EWRAPPER_TOKENIZED_NOT_TOKENIZED`: If the wrapper does not contain the specified item.
    public fun has_wrapper(wt: &Wrapper, id: ID) {
        is_tokenized(wt);
        assert!(dof::exists_with_type<Item, Wrapper>(&wt.id, Item { id }) && vector::contains<vector<u8>>(&wt.items,&id.to_bytes()) , EWRAPPER_TOKENIZED_NOT_TOKENIZED);
    }

    /// Asserts that the given wrapper does not have the specified wrapper item.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Errors:
    /// - `EWRAPPER_TOKENIZED_HAS_TOKENIZED`: If the wrapper contains the specified item.
    public fun not_wrapper(wt: &Wrapper, id: ID) {
        is_tokenized(wt);
        assert!(!dof::exists_with_type<Item, Wrapper>(&wt.id, Item { id }) && vector::contains<vector<u8>>(&wt.items,&id.to_bytes()) , EWRAPPER_TOKENIZED_HAS_TOKENIZED);
    }

    /// Asserts that the caller has access to the wrapper.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// - `ctx`: Reference to the transaction context.
    /// Errors:
    /// - `EWRAPPER_TOKENIZED_NOT_ACCESS`: If the caller does not have access.
    fun has_access(wt: &Wrapper, ctx: &TxContext) {
        is_tokenized(wt);
        let lock = df::borrow<Item,Lock>(&wt.id, Item { id: object::id(wt) });
        assert!(lock.owner.is_some() && ctx.sender() == lock.owner.borrow(),EWRAPPER_TOKENIZED_NOT_ACCESS)
    }

    // ===== Tokenized Public Entry functions =====

    /// Event emitted when a tokenized object is created.
    public struct Tokenized<phantom T: drop> has copy, drop {
        id: ID,
        object: ID,
        treasury: ID,
        supply: u64,
        deposit: u64,
    }

    /// Tokenizes the given object with the specified treasury.
    /// Treasury may be used to mint new tokens, and the object may be locked to prevent further minting.
    /// there can fund the sui, and lock the object, and the owner can be withdraw the fund.
    /// Parameters:
    /// - `treasury`: Treasury capability representing the total supply.
    /// - `total_supply`: Total supply amount.
    /// - `o`: Object ID.
    /// - `sui`: Coin of SUI.
    /// - `wrapper`: Mutable reference to the Wrapper.
    /// - `ctx`: Mutable reference to the transaction context.
    /// Errors:
    /// - `ETOKEN_SUPPLY_MISMATCH`: If the treasury's total supply is greater than the input total supply.
    public entry fun tokenized<T: drop>(treasury:TreasuryCap<T>,total_supply:u64,o:ID,mut sui:Coin<SUI>,wrapper:&mut Wrapper,ctx: &mut TxContext) {
        is_tokenized(wrapper);
        // TODO 
        // let inception = INCEPTION_WRAPPER_OBJECT_ID;
        // assert!(wrapper.item(0) == inception.to_bytes() , ENOT_INCEPTION_TOKENIZED_WRAPPER);
        // assert!(sui.value() >= 2 * SUI_MIST_PER_SUI, EINVALID_SUI_VALUE);

        // locked treasury total supply must smaller than input total_supply
        assert!(treasury.total_supply() <= total_supply, ETOKEN_SUPPLY_MISMATCH);

        // create a new tokenized object wrapper
        let mut wt = new(ctx);
        wt.kind = std::ascii::string(TOKENIZED_WRAPPER_KIND);
        wt.alias = std::string::from_ascii(type_name::get_module(&type_name::get<T>()));
    
        // some id
        let tid = object::id(&treasury);
        let wtid = object::id(&wt);

        // emit event
        event::emit(Tokenized<T> {
            id: wtid,
            object: o,
            treasury: tid,
            supply: total_supply,
            deposit: sui.value()
        });

        // core internal
        let vault = coin::split<SUI>(&mut sui,2 * SUI_MIST_PER_SUI,ctx);
        stocking(wrapper,vault,ctx);
        df::add(&mut wt.id,
            Item { id: wtid },
            Lock { 
                id: o,
                owner: option::some(ctx.sender()),
                total_supply: total_supply,
                fund: sui.into_balance()
            }
        );
        // add items ,but not dof add item,means not add to the object store
        wt.items.push_back(o.to_bytes());
        // dof::add(&mut wt.id, Item{ id: oid }, wrapper_tokenized);
        
        // add treasury,means the treasury is in the object store
        wt.items.push_back(tid.to_bytes());
        dof::add(&mut wt.id, Item{ id: tid }, treasury);

        // share the tokenized wrapper with the treasury
        transfer::public_share_object(wt);
    }
    
    #[lint_allow(self_transfer)]
    /// Detokenizes a tokenized wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `ctx`: Mutable reference to the transaction context.
    /// Errors:
    /// - `EWRAPPER_TOKENIZED_NOT_ACCESS`: If the caller does not have access.
    public entry fun detokenized<T: drop>(mut wt: Wrapper, ctx: &mut TxContext) {
        // check has access
        has_access(&wt,ctx);
        
        // transfer treasury to sender
        let treasury_id = object::id_from_bytes(wt.item(1));
        let treasury:TreasuryCap<T> = dof::remove<Item,TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
        transfer::public_transfer(treasury, tx_context::sender(ctx));

        // transfer fund to sender and delete Lock
        let wtid = object::id(&wt);
        let Lock { id:_,owner:_,total_supply:_,fund} = df::remove<Item,Lock>(&mut wt.id, Item { id: wtid });
        transfer::public_transfer(coin::from_balance<SUI>(fund,ctx), tx_context::sender(ctx));

        // delete the tokenized object wrapper
        wt.items.swap_remove(0);
        wt.items.swap_remove(0);
        wt.destroy_empty();
    }
    

    /// Stocks additional funds into a tokenized object wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `sui`: Coin of SUI.
    /// - `ctx`: Mutable reference to the transaction context.
    public entry fun stocking(wt:&mut Wrapper,sui:Coin<SUI>,ctx: &mut TxContext) {
        is_tokenized(wt);
        let wtid = object::id(wt);
        let mut lock = df::borrow_mut<Item,Lock>(&mut wt.id, Item { id: wtid });
        lock.fund.join<SUI>(sui.into_balance());
    }

    /// Withdraws funds from a tokenized object wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `value`: Amount of funds to withdraw.
    /// - `ctx`: Mutable reference to the transaction context.
    /// Errors:
    /// - `EINSUFFICIENT_BALANCE`: If the wrapper's fund balance is less than the requested withdrawal amount.
    #[lint_allow(self_transfer)]
    public entry fun withdraw(wt: &mut Wrapper,value: u64,ctx: &mut TxContext) {
        // Ensure the wrapper is tokenized
        is_tokenized(wt);
        // Ensure the caller has access to the wrapper
        has_access(wt, ctx);
        // Get the wrapper ID
        let wtid = object::id(wt);
        // Borrow the lock mutably from the data frame
        let mut lock = df::borrow_mut<Item, Lock>(&mut wt.id, Item { id: wtid });
        // Check if the wrapper's fund balance is sufficient for the withdrawal
        assert!(lock.fund.value() >= value, EINSUFFICIENT_BALANCE);
        // Split the specified amount from the fund
        let c = coin::from_balance<SUI>(lock.fund.split<SUI>(value), ctx);
        // Transfer the withdrawn funds to the sender
        transfer::public_transfer(c, ctx.sender());
    }


    #[lint_allow(self_transfer)]
    /// Locks the given wrapper with the specified total supply.
    /// Lock the wrapper with the total supply, and transfer the SUI fund to the sender.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `o`: The Wrapper to lock.
    /// - `ctx`: Mutable reference to the transaction context.
    public entry fun lock(wt:& mut Wrapper,o: Wrapper, ctx: &mut TxContext) {
        // check if wrapper is not locked,must be none
        not_wrapper(wt,object::id(&o));
        // fill the lock owner and total_supply
        let wtid = object::id(wt);
        let mut lock = df::borrow_mut<Item,Lock>(&mut wt.id, Item { id: wtid });
        // fill the owner
        option::fill(&mut lock.owner, ctx.sender());
        // withdraw SUI fund to the sender
        transfer::public_transfer(coin::from_balance<SUI>(balance::withdraw_all(&mut lock.fund),ctx), ctx.sender());
        
        // fill the wrapper and owner
        dof::add(&mut wt.id, Item{ id: object::id(&o) }, o);
    }

    #[lint_allow(self_transfer)]
    /// Unlocks the given wrapper.
    /// Unlocks the wrapper by burning the total supply of the tokenized wrapper and transferring the ownership of the locked wrapper to the sender.
    /// The total supply must match the treasury supply, and the total supply must be zero.
    /// If user lock wrapper to withdraw the SUI, the hacker must burn all the token to unlock the wrapper.
    /// So user can reserve the token,avoid the hacker to withdraw the SUI,and unlock the wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `ctx`: Mutable reference to the transaction context.
    /// Errors:
    /// - `ETOKEN_SUPPLY_MISMATCH`: If the total supply does not match the treasury supply.
    /// - `ECANNOT_UNLOCK_NON_ZERO_SUPPLY`: If the total supply is not zero.
    public entry fun unlock<T: drop>(mut wt: Wrapper, ctx: &mut TxContext) {
        // check has access
        has_access(&wt,ctx);
        // burn total supply of tokenized wrapper to unlock wrapper
        let total_supply = total_supply(&wt);
        let treasury_supply = treasury_supply<T>(&wt);
        assert!(total_supply == treasury_supply, ETOKEN_SUPPLY_MISMATCH);
        assert!(total_supply == 0, ECANNOT_UNLOCK_NON_ZERO_SUPPLY);

        // transfer locked wrapper ownership to sender
        let object_id = object::id_from_bytes(wt.item(0));
        has_wrapper(&wt,object_id);
        let object: Wrapper = dof::remove<Item,Wrapper>(&mut wt.id, Item { id:object_id });
        transfer::public_transfer(object, tx_context::sender(ctx));

        // detokenized the wrapper
        detokenized<T>(wt,ctx);
    }

    /// Mints new tokens for the given wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `value`: Amount of tokens to mint.
    /// - `ctx`: Mutable reference to the transaction context.
    /// Errors:
    /// - `ETOKEN_SUPPLY_MISMATCH`: If the value to mint exceeds the maximum supply.
    public entry fun mint<T:drop>(wt: &mut Wrapper, value: u64, ctx: &mut TxContext) {
        // check has access
        has_access(wt,ctx);

        // check if total supply is less than max supply
        let total_supply = total_supply(wt);
        let treasury_supply = treasury_supply<T>(wt);
        assert!(value + treasury_supply <= total_supply, ETOKEN_SUPPLY_MISMATCH);

        // mint token
        let treasury_id = object::id_from_bytes(wt.item(1));
        let mut treasury = dof::borrow_mut<Item,TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
        let token = coin::mint(treasury, value, ctx);

        // transfer token to owner
        transfer::public_transfer(token, tx_context::sender(ctx));
    }

    /// Burns tokens from the given wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `c`: The Coin to burn.
    public entry fun burn<T:drop>(wt: &mut Wrapper, c: Coin<T>) {
        is_tokenized(wt);
        // burn token
        let treasury_id = object::id_from_bytes(wt.item(1));
        let burn_value = c.value();
        let mut treasury = dof::borrow_mut<Item,TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
        coin::burn(treasury, c);
        
        // update total supply
        let wtid = object::id(wt);
        let mut lock = df::borrow_mut<Item,Lock>(&mut wt.id, Item { id: wtid });
        lock.total_supply = lock.total_supply - burn_value;
    }

    /// Gets the total supply of the tokenized wrapper.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// Returns: 
    /// - The total supply.
    public fun total_supply(wt: &Wrapper): u64 {
        is_tokenized(wt);
        let lock = df::borrow<Item,Lock>(&wt.id, Item { id: object::id(wt) });
        lock.total_supply
    }

    /// Gets the current supply of the treasury.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// Returns: 
    /// - The current supply.
    public fun treasury_supply<T:drop>(wt: &Wrapper): u64 {
        is_tokenized(wt);
        let treasury_id = object::id_from_bytes(wt.item(1));
        let treasury = dof::borrow<Item,TreasuryCap<T>>(&wt.id, Item { id: treasury_id });
        treasury.total_supply()
    }
}