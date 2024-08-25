#[allow(unused_use)]
/// Module: core
/// Github: https://github.com/0xWrapper/wrapper
/// Provides functionality for managing a collection of objects within a "Wrapper".
/// This module includes functionalities to wrap, unwrap, merge, split, and manage items in a Wrapper.
/// It handles different kinds of objects and ensures that operations are type-safe.
module wrapper::wrapper {
    use std::ascii;
    use std::type_name;
    use sui::dynamic_object_field as dof;
    use sui::dynamic_field as df;
    use sui::event;
    use wrapper::wrap::init_coin;
    use sui::transfer::Receiving;
    use discover::message;

    // ===== Error Codes =====
    const EWrapperNotEmpty: u64 = 0;
    const EIndexOutOfWrapperItemsBounds: u64 = 1;

    // ===== Wrapper Kind Constants =====
    const EMPTY_WRAPPER_KIND: vector<u8> = b"EMPTY WRAPPER";
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
        kind: std::ascii::String,
        //type of wrapped object
        alias: std::string::String,
        // alias for the Wrapper
        items: vector<vector<u8>>,
        // wrapped object ids
        content: std::string::String,
        // content url for the Wrapper
    }

    // ===== Initial functions =====

    /// Event emitted when Wrapper Protocal is initialized.
    public struct Init has copy, drop {
        creater: address,
        incentive: ID,
        inception: ID,
    }


    #[lint_allow(self_transfer)]
    /// Initializes a new Wrapper and sets up its display and publisher.
    /// Claims a publisher using the provided WRAPPER object and initializes the display.
    /// Parameters:
    /// - `witness`: A one-time witness object for claiming the package.
    /// - `ctx`: Transaction context for managing blockchain-related operations.
    /// Effect:
    /// - Transfers the ownership of the publisher and display to the transaction sender.
    fun init(witness: WRAPPER, ctx: &mut TxContext) {
        let genesis = init_inception(ctx);
        let treasury = init_coin(witness, ctx);
        event::emit(Init {
            creater: tx_context::sender(ctx),
            incentive: object::id(&treasury),
            inception: object::id(&genesis),
        });
        transfer::public_transfer(treasury, ctx.sender());
        transfer::public_transfer(genesis, ctx.sender());
    }


    // ===== Basic Functions =====
    /// Event emitted when Wrapper is created.
    public struct Created has copy, drop {
        creater: address,
        id: ID,
    }

    /// PointsMessage emitted when Wrapper is created.
    /// Send to Wrapper Discover Space Cap
    public struct PointsMessage has store {
        points: u64,
    }

    /// get a reward points
    public(package) fun reward(points: u64): PointsMessage {
        PointsMessage {
            points
        }
    }

    /// Creates a new, empty Wrapper.
    /// Parameters:
    /// - `ctx`: Transaction context used for creating the Wrapper.
    /// Returns:
    /// - A new Wrapper with no items and a generic kind.
    public fun new(ctx: &mut TxContext): Wrapper {
        message::produce(reward(6), ctx.sender(), ctx);
        let id = object::new(ctx);
        event::emit(Created {
            creater: tx_context::sender(ctx),
            id: id.to_inner(),
        });
        Wrapper {
            id,
            kind: std::ascii::string(EMPTY_WRAPPER_KIND),
            alias: std::string::utf8(EMPTY_WRAPPER_KIND),
            items: vector[],
            content: std::string::utf8(b""),
        }
    }

    /// Event emitted when Wrapper is destroy.
    public struct Destroyed has copy, drop {
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
        let Wrapper { id, kind, alias: _, items: _, content: _ } = w;
        event::emit(Destroyed {
            id: id.to_inner(),
            kind,
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
        w.kind() == std::ascii::string(EMPTY_WRAPPER_KIND) || w.count() == 0
    }

    // ===== Basic property functions =====
    /// Accepts a receiving object into the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `to_receive`: The object to receive.
    /// Returns:
    /// - The received object.
    public fun accept<T: key+store>(w: &mut Wrapper, to_receive: Receiving<T>): T {
        transfer::public_receive(&mut w.id, to_receive)
    }

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
        assert!(w.count() > i, EIndexOutOfWrapperItemsBounds);
        w.items[i]
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

    // ===== Basic Package functions =====

    /// Empties the wrapper and sets its kind to `EMPTY_WRAPPER_KIND`.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// Errors:
    /// - `EWrapperNotEmpty`: If the wrapper is not empty.
    public(package) fun empty(w: &mut Wrapper) {
        assert!(w.is_empty(), EWrapperNotEmpty);
        w.set_kind(ascii::string(EMPTY_WRAPPER_KIND));
    }

    /// Sets the kind of the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `kind`: The new kind to set.
    public(package) fun set_kind(w: &mut Wrapper, kind: ascii::String) {
        w.kind = kind;
    }

    /// Adds an item to the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `item`: The item to add.
    public(package) fun add_item(w: &mut Wrapper, item: vector<u8>) {
        vector::push_back(&mut w.items, item);
    }

    /// Removes an item from the wrapper at the specified index.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `index`: The index of the item to remove.
    /// Returns:
    /// - The removed item.
    public(package) fun remove_item(w: &mut Wrapper, index: u64): vector<u8> {
        if (index >= w.count()) {
            vector::pop_back(&mut w.items)
        }else {
            vector::swap_remove(&mut w.items, index)
        }
    }

    /// Adds an object to the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `k`: The key of the object.
    /// - `v`: The value of the object.
    public(package) fun add_object<K: copy + drop + store, V: key + store>(w: &mut Wrapper, k: K, v: V) {
        dof::add(&mut w.id, k, v);
    }

    /// Checks if an object exists in the wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `k`: The key of the object.
    /// Returns:
    /// - `true` if the object exists, `false` otherwise.
    public(package) fun exists_object<K: copy + drop + store, V: key + store>(w: &Wrapper, k: K): bool {
        dof::exists_with_type<K, V>(&w.id, k)
    }

    /// Mutates an object in the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `k`: The key of the object.
    /// Returns:
    /// - Mutable reference to the object.
    public(package) fun mutate_object<K: copy + drop + store, V: key + store>(w: &mut Wrapper, k: K): &mut V {
        dof::borrow_mut<K, V>(&mut w.id, k)
    }


    /// Borrows an object from the wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `k`: The key of the object.
    /// Returns:
    /// - Reference to the object.
    public(package) fun borrow_object<K: copy + drop + store, V: key + store>(w: &Wrapper, k: K): &V {
        dof::borrow<K, V>(&w.id, k)
    }

    /// Removes an object from the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `k`: The key of the object.
    /// Returns:
    /// - The removed object.
    public(package) fun remove_object<K: copy + drop + store, V: key + store>(w: &mut Wrapper, k: K): V {
        dof::remove<K, V>(&mut w.id, k)
    }

    /// Adds a field to the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `k`: The key of the field.
    /// - `v`: The value of the field.
    public(package) fun add_field<K: copy + drop + store, V: store>(w: &mut Wrapper, k: K, v: V) {
        df::add(&mut w.id, k, v);
    }

    /// Checks if a field exists in the wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `k`: The key of the field.
    /// Returns:
    /// - `true` if the field exists, `false` otherwise.
    public(package) fun exists_field<K: copy + drop + store, V: store>(w: &Wrapper, k: K): bool {
        df::exists_with_type<K, V>(&w.id, k)
    }

    /// Mutates a field in the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `k`: The key of the field.
    /// Returns:
    /// - Mutable reference to the field.
    public(package) fun mutate_field<K: copy + drop + store, V: store>(w: &mut Wrapper, k: K): &mut V {
        df::borrow_mut<K, V>(&mut w.id, k)
    }

    /// Borrows a field from the wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `k`: The key of the field.
    /// Returns:
    /// - Reference to the field.
    public(package) fun borrow_field<K: copy + drop + store, V: store>(w: &Wrapper, k: K): &V {
        df::borrow<K, V>(&w.id, k)
    }

    /// Removes a field from the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `k`: The key of the field.
    /// Returns:
    /// - The removed field.
    public(package) fun remove_field<K: copy + drop + store, V: store>(w: &mut Wrapper, k: K): V {
        df::remove<K, V>(&mut w.id, k)
    }

    // ===== Inception =====

    const INCEPTION_WRAPPER_KIND: vector<u8> = b"INCEPTION WRAPPER";

    /// Checks if the Wrapper is inception.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the Wrapper is just create on init, false otherwise.
    public fun is_inception(w: &Wrapper): bool {
        w.kind() == std::ascii::string(INCEPTION_WRAPPER_KIND)
    }

    /// Creates a new Wrapper with the INKSCRIPTION kind.
    fun init_inception(ctx: &mut TxContext): Wrapper {
        let mut inception = new(ctx);
        inception.set_kind(ascii::string(INCEPTION_WRAPPER_KIND));
        inception.set_alias(std::string::utf8(b"The Dawn of Wrapper Protocol"));
        inception.set_content(std::string::utf8(
            b"https://ipfs.filebase.io/ipfs/QmYZgGG5QSegRZQg8p2MXMkzwdYLu6fWvLDCbFL8fhPNZX"
        ));

        // inkscribe
        inception.add_item(b"In Genesis, the birth of vision's light,");
        inception.add_item(b"Prime movers seek the endless flight.");
        inception.add_item(b"Origin of dreams in tokens cast,");
        inception.add_item(b"Alpha minds, forging futures vast.");

        inception.add_item(b"Pioneers of liquidity's rise,");
        inception.add_item(b"Inception's brilliance in our eyes.");
        inception.add_item(b"First steps in a realm so grand,");
        inception.add_item(b"Proto solutions, deftly planned.");

        inception.add_item(b"Founding pillars of trust and trade,");
        inception.add_item(b"Eureka moments that never fade.");
        inception.add_item(b"In Wrapper's embrace, assets entwine,");
        inception.add_item(b"Revolution in every design.");

        inception.add_item(b"Smart contracts, decentralized might,");
        inception.add_item(b"Liquidity pools, shining bright.");
        inception.add_item(b"Tokenization's seamless grace,");
        inception.add_item(b"In every swap, a better place.");

        inception.add_item(b"Yield and NFTs display,");
        inception.add_item(b"In dynamic, flexible sway.");
        inception.add_item(b"From blind boxes to swap's exchange,");
        inception.add_item(b"In Wrapper's world, nothing's strange.");

        inception.add_item(b"In Genesis, we lay the ground,");
        inception.add_item(b"Prime visions in Wrapper found.");
        inception.add_item(b"With every step, we redefine,");
        inception.add_item(b"A future bright, in Wrapper's line.");
        inception
    }


    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(WRAPPER {}, ctx);
    }
}