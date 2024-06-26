// #[allow(unused_use)]
// /// Module: wrapper
// /// Github: https://github.com/0xWrapper/wrapper
// /// Provides functionality for managing a collection of objects within a "Wrapper".
// /// This module includes functionalities to wrap, unwrap, merge, split, and manage items in a Wrapper.
// /// It handles different kinds of objects and ensures that operations are type-safe.
// module wrapper::wrapper {
//     use std::ascii;
//     use std::type_name;
//     use sui::dynamic_object_field as dof;
//     use sui::dynamic_field as df;
//     use sui::display;
//     use sui::package;
//     use sui::event;
//     use sui::object;
//     use sui::tx_context;
//     use sui::transfer;
//     use sui::clock::Clock;
//     use sui::balance::{Self, Balance};
//     use sui::sui::{SUI};
//
//     // == vesting ==
//     use sui::hash::{ blake2b256};
//
//     // == tokenized ==
//     use std::vector::{Self};
//     use std::option;
//     use std::string;
//     use sui::bcs;
//     use sui::clock;
//     use sui::coin::{Self, Coin, TreasuryCap};
//     use sui::object::ID;
//     use sui::transfer::public_transfer;
//
//     // == vault ==
//     use sui::transfer::{ Receiving};
//
//
//     // ===== Error Codes =====
//     const EItemNotFound: u64 = 0;
//     const EIndexOutOfBounds: u64 = 1;
//     const EItemNotSameKind: u64 = 2;
//     const EItemNotFoundOrNotSameKind: u64 = 3;
//     const EWrapperNotEmpty: u64 = 4;
//
//     // === InkSciption Error Codes ===
//     const EWrapperNotEmptyOrInkSciption: u64 = 5;
//
//     // === TOKENIZED Error Codes ===
//     const ENOT_TOKENIZED_WRAPPER: u64 = 6;
//     const EWRAPPER_TOKENIZED_MISMATCH: u64 = 7;
//     const EWRAPPER_TOKENIZED_NOT_TREASURY: u64 = 8;
//     const EWRAPPER_TOKENIZED_NOT_LOCK: u64 = 9;
//     const EWRAPPER_TOKENIZED_NOT_TOKENIZED: u64 = 10;
//     const EWRAPPER_TOKENIZED_HAS_TOKENIZED: u64 = 11;
//     const EWRAPPER_TOKENIZED_NOT_ACCESS: u64 = 12;
//     const EWRAPPER_TOKENIZED_HAS_OWNER: u64 = 13;
//     const ECANNOT_UNLOCK_NON_ZERO_SUPPLY: u64 = 14;
//     const ETOKEN_SUPPLY_MISMATCH: u64 = 15;
//     const EINVALID_SUI_VALUE: u64 = 16;
//     const EINSUFFICIENT_BALANCE: u64 = 17;
//
//
//     // === Vesting Error Codes ===
//     const EWrapperNotEmptyOrVesting: u64 = 18;
//     const EWrapperNotVesting: u64 = 19;
//     const EInvalidReleaseAmount: u64 = 19;
//     const EVestingWrapperHasRelease: u64 = 20;
//     const EWrapperNotReleaseVesting: u64 = 21;
//     const EVestingWrapperNotVestingType: u64 = 21;
//     const ECycleMustBeAtLeastOneDay: u64 = 22;
//     const ECycleMustBeMultipleOfDay: u64 = 23;
//     const EInitialExceedsLimit: u64 = 23;
//     const EStartExceedsLimit: u64 = 24;
//     const ECannotClaimBeforeStart: u64 = 25;
//     const EVestingCycleMustGTECliffCycle: u64 = 25;
//     const EInvalidSeparateAmount: u64 = 25;
//     const EInvalidRevokeAmount: u64 = 25;
//     const EVestingNotSameKind: u64 = 25;
//     const EInvalidVestingSyncCall: u64 = 25;
//
//     // ====== Vault Error Codes =====
//     const ENOT_VAULT_WRAPPER: u64 = 25;
//     const EWrapperNotEmptyOrVault: u64 = 25;
//     const EAssetNotFoundInVault: u64 = 25;
//     const ECurrencyNotFoundInVault: u64 = 25;
//     const ECurrencyNotEnoughFoundInVault: u64 = 25;
//
//     // ===== Wrapper Kind Constants =====
//     const EMPTY_WRAPPER_KIND: vector<u8> = b"EMPTY WRAPPER";
//     const INKSCRIPTION_WRAPPER_KIND: vector<u8> = b"INKSCRIPTION WRAPPER";
//     const TOKENIZED_WRAPPER_KIND: vector<u8> = b"TOKENIZATION WRAPPER";
//     const INCEPTION_WRAPPER_KIND: vector<u8> = b"INCEPTION WRAPPER";
//     const VESTING_WRAPPER_KIND: vector<u8> = b"VESTING WRAPPER";
//     const VAULT_WRAPPER_KIND: vector<u8> = b"VAULT WRAPPER";
//
//
//     const SUI_MIST_PER_SUI: u64 = 1_000_000_000;
//     const VESTING_DEPLOY_TIME_MS: u64 = 1_718_000_000_000;
//
//     // inception wrapper object id
//     const INCEPTION_WRAPPER_OBJECT_ID: address = @0x6;
//
//     // ===== Wrapper Core Struct =====
//
//     /// A one-time witness object used for claiming packages and transferring ownership within the Sui framework.
//     /// This object is used to initialize and setup the display and ownership of newly created Wrappers.
//     public struct WRAPPER has drop {}
//
//     /// Represents a container for managing a set of objects.
//     /// Each object is identified by an ID and the Wrapper tracks the type of objects it contains.
//     /// Fields:
//     /// - `id`: Unique identifier for the Wrapper.
//     /// - `kind`: ASCII string representing the type of objects the Wrapper can contain.
//     /// - `alias`: UTF8 encoded string representing an alias for the Wrapper.
//     /// - `items`: Vector of IDs or Other Bytes representing the objects wrapped.
//     /// - `content`: Image or Other Content of the Wrapper.
//     public struct Wrapper has key, store {
//         id: UID,
//         kind: std::ascii::String,
//         //type of wrapped object
//         alias: std::string::String,
//         // alias for the Wrapper
//         items: vector<vector<u8>>,
//         // wrapped object ids
//         content: std::string::String,
//         // content url for the Wrapper
//     }
//
//     // ===== Initial functions =====
//
//     /// Event emitted when Wrapper Protocal is initialized.
//     public struct Init has copy, drop {
//         creater: address,
//         publisher: ID,
//         display: ID,
//         inception: ID,
//     }
//
//     /// Checks if the Wrapper is inception.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - True if the Wrapper is just create on init, false otherwise.
//     public fun is_inception(w: &Wrapper): bool {
//         w.kind == std::ascii::string(INCEPTION_WRAPPER_KIND)
//     }
//
//     #[lint_allow(self_transfer)]
//     /// Initializes a new Wrapper and sets up its display and publisher.
//     /// Claims a publisher using the provided WRAPPER object and initializes the display.
//     /// Parameters:
//     /// - `witness`: A one-time witness object for claiming the package.
//     /// - `ctx`: Transaction context for managing blockchain-related operations.
//     /// Effect:
//     /// - Transfers the ownership of the publisher and display to the transaction sender.
//     fun init(witness: WRAPPER, ctx: &mut TxContext) {
//         let publisher = package::claim(witness, ctx);
//         let keys = vector[
//             std::string::utf8(b"kind"),
//             std::string::utf8(b"alias"),
//             std::string::utf8(b"image_url"),
//             std::string::utf8(b"project_url"),
//         ];
//         let values = vector[
//             std::string::utf8(b"{kind}"),
//             std::string::utf8(b"{alias}"),
//             std::string::utf8(b"{content}"),
//             std::string::utf8(b"https://wrapper.space"),
//         ];
//         let mut display = display::new_with_fields<Wrapper>(&publisher, keys, values, ctx);
//         display::update_version<Wrapper>(&mut display);
//         // Genesis Wrapper
//         let genesis = inception(ctx);
//         event::emit(Init {
//             creater: tx_context::sender(ctx),
//             publisher: object::id(&publisher),
//             display: object::id(&display),
//             inception: object::id(&genesis),
//         });
//
//         transfer::public_transfer(publisher, tx_context::sender(ctx));
//         transfer::public_transfer(display, tx_context::sender(ctx));
//         transfer::public_transfer(genesis, tx_context::sender(ctx));
//     }
//
//     /// Creates a new Wrapper with the INKSCRIPTION kind.
//     fun inception(ctx: &mut TxContext): Wrapper {
//         let mut inception = new(ctx);
//         inception.kind = std::ascii::string(b"INCEPTION WRAPPER");
//         inception.alias = std::string::utf8(b"The Dawn of Wrapper Protocol");
//         inception.content = std::string::utf8(
//             b"https://ipfs.filebase.io/ipfs/QmYZgGG5QSegRZQg8p2MXMkzwdYLu6fWvLDCbFL8fhPNZX"
//         );
//
//         vector::push_back(&mut inception.items, b"In Genesis, the birth of vision's light,");
//         vector::push_back(&mut inception.items, b"Prime movers seek the endless flight.");
//         vector::push_back(&mut inception.items, b"Origin of dreams in tokens cast,");
//         vector::push_back(&mut inception.items, b"Alpha minds, forging futures vast.");
//
//         vector::push_back(&mut inception.items, b"Pioneers of liquidity's rise,");
//         vector::push_back(&mut inception.items, b"Inception's brilliance in our eyes.");
//         vector::push_back(&mut inception.items, b"First steps in a realm so grand,");
//         vector::push_back(&mut inception.items, b"Proto solutions, deftly planned.");
//
//         vector::push_back(&mut inception.items, b"Founding pillars of trust and trade,");
//         vector::push_back(&mut inception.items, b"Eureka moments that never fade.");
//         vector::push_back(&mut inception.items, b"In Wrapper's embrace, assets entwine,");
//         vector::push_back(&mut inception.items, b"Revolution in every design.");
//
//         vector::push_back(&mut inception.items, b"Smart contracts, decentralized might,");
//         vector::push_back(&mut inception.items, b"Liquidity pools, shining bright.");
//         vector::push_back(&mut inception.items, b"Tokenization's seamless grace,");
//         vector::push_back(&mut inception.items, b"In every swap, a better place.");
//
//         vector::push_back(&mut inception.items, b"Yield and NFTs display,");
//         vector::push_back(&mut inception.items, b"In dynamic, flexible sway.");
//         vector::push_back(&mut inception.items, b"From blind boxes to swap's exchange,");
//         vector::push_back(&mut inception.items, b"In Wrapper's world, nothing's strange.");
//
//         vector::push_back(&mut inception.items, b"In Genesis, we lay the ground,");
//         vector::push_back(&mut inception.items, b"Prime visions in Wrapper found.");
//         vector::push_back(&mut inception.items, b"With every step, we redefine,");
//         vector::push_back(&mut inception.items, b"A future bright, in Wrapper's line.");
//         inception
//     }
//
//     //   public entry fun register<T: drop>(
//     //     witness: T,
//     //     decimals: u8,
//     //     symbol: vector<u8>,
//     //     name: vector<u8>,
//     //     description: vector<u8>,
//     //     icon_url: vector<u8>,
//     //     object: address,
//     //     ctx: &mut TxContext
//     // ) {
//     //     // check tokenized object is equal to witness type name
//     //     check_tokenized_object<T>(object);
//     //     let icon_url = if (icon_url == b"") {
//     //         option::none()
//     //     } else {
//     //         option::some(url::new_unsafe_from_bytes(icon_url))
//     //     };
//     //     // create a new currency
//     //     let (treasury, metadata) = coin::create_currency(witness,decimals,symbol,name,description,icon_url,ctx);
//     //     transfer::public_freeze_object(metadata);
//
//     //     // share the tokenized object wrapper with the treasury
//     //     tokenized<T>(treasury,object,ctx);
//     // }
//
//
//     // ===== Basic Functions =====
//
//
//     /// Event emitted when Wrapper is created.
//     public struct Create has copy, drop {
//         creater: address,
//         id: ID,
//     }
//
//     /// Creates a new, empty Wrapper.
//     /// Parameters:
//     /// - `ctx`: Transaction context used for creating the Wrapper.
//     /// Returns:
//     /// - A new Wrapper with no items and a generic kind.
//     public fun new(ctx: &mut TxContext): Wrapper {
//         let id = object::new(ctx);
//         event::emit(Create {
//             creater: tx_context::sender(ctx),
//             id: id.to_inner(),
//         });
//         Wrapper {
//             id: id,
//             kind: std::ascii::string(EMPTY_WRAPPER_KIND),
//             alias: std::string::utf8(EMPTY_WRAPPER_KIND),
//             items: vector[],
//             content: std::string::utf8(b""),
//         }
//     }
//
//     /// Event emitted when Wrapper is destroy.
//     public struct Destroy has copy, drop {
//         id: ID,
//         kind: std::ascii::String,
//     }
//
//     /// Destroys the Wrapper, ensuring it is empty before deletion.
//     /// Parameters:
//     /// - `w`: The Wrapper to destroy.
//     /// Effects:
//     /// - The Wrapper and its identifier are deleted.
//     /// Errors:
//     /// - `EWrapperNotEmpty`: If the Wrapper is not empty at the time of destruction.
//     public fun destroy_empty(w: Wrapper) {
//         // remove all items from the Wrapper
//         assert!(w.is_empty(), EWrapperNotEmpty);
//         // delete the Wrapper
//         let Wrapper { id, kind: kind, alias: _, items: _, content: _ } = w;
//         event::emit(Destroy {
//             id: id.to_inner(),
//             kind: kind,
//         });
//         id.delete();
//     }
//
//     // ===== Basic Check functions =====
//
//     /// Checks if the specified type T matches the kind of items stored in the Wrapper.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - True if the type T matches the Wrapper's kind, false otherwise.
//     public fun is_same_kind<T: key + store>(w: &Wrapper): bool {
//         w.kind == type_name::into_string(type_name::get<T>())
//     }
//
//     /// Checks if the Wrapper is empty.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - True if the Wrapper contains no items, false otherwise.
//     public fun is_empty(w: &Wrapper): bool {
//         w.kind == std::ascii::string(EMPTY_WRAPPER_KIND) || w.count() == 0
//     }
//
//     // ===== Basic property functions =====
//
//     /// Retrieves the kind of objects contained within the Wrapper.
//     /// Returns an ASCII string representing the type of the wrapped objects.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - ASCII string indicating the kind of objects in the Wrapper.
//     public fun kind(w: &Wrapper): std::ascii::String {
//         w.kind
//     }
//
//     /// Retrieves the alias of the Wrapper.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - UTF8 encoded string representing the alias of the Wrapper.
//     public fun alias(w: &Wrapper): std::string::String {
//         w.alias
//     }
//
//     /// Retrieves all object IDs contained within the Wrapper.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - A vector of some items or IDs representing all objects within the Wrapper.
//     public fun items(w: &Wrapper): vector<vector<u8>> {
//         w.items
//     }
//
//     /// Returns the number of objects contained within the Wrapper.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - The count of items in the Wrapper as a 64-bit unsigned integer.
//     public fun count(w: &Wrapper): u64 {
//         w.items.length()
//     }
//
//     /// Retrieves the ID of the object at a specified index within the Wrapper.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// - `i`: Index of the item to retrieve.
//     /// Returns:
//     /// - item or ID of the object at the specified index.
//     /// Errors:
//     /// - `EIndexOutOfBounds`: If the provided index is out of bounds.
//     public fun item(w: &Wrapper, i: u64): vector<u8> {
//         if (w.count() <= i) {
//             abort EIndexOutOfBounds
//         }else {
//             w.items[i]
//         }
//     }
//
//     // ===== Basic Public Entry functions =====
//
//     /// Sets a new alias for the Wrapper.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `alias`: New alias to set for the Wrapper.
//     /// Effects:
//     /// - Updates the alias field of the Wrapper.
//     public entry fun set_alias(w: &mut Wrapper, alias: std::string::String) {
//         w.alias = alias;
//     }
//
//     /// Sets a new content for the Wrapper
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `content`: New content to set for the Wrapper.
//     /// Effects:
//     /// - Updates the content field of the Wrapper.
//     public entry fun set_content(w: &mut Wrapper, content: std::string::String) {
//         w.content = content;
//     }
//
//
//     // =============== Ink Extension Functions ===============
//
//     // ===== Ink Check functions =====
//
//     /// Checks if the Wrapper is inkscription.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - True if the Wrapper only contains items, false otherwise.
//     public fun is_inkscription(w: &Wrapper): bool {
//         w.kind == std::ascii::string(INKSCRIPTION_WRAPPER_KIND)
//     }
//
//     // ===== Ink Public Entry functions =====
//
//     /// Event emitted when some ink is scribe to the Wrapper.
//     public struct Scribing has copy, drop {
//         id: ID,
//         inks: u64,
//     }
//
//     /// Appends an ink inscription to the Wrapper.
//     /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `ink`: The string to be inscribed.
//     /// Errors:
//     /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is neither empty nor an inscription.
//     public entry fun inkscribe(w: &mut Wrapper, mut ink: vector<std::string::String>) {
//         assert!(w.is_inkscription() || w.is_empty(), EWrapperNotEmptyOrInkSciption);
//         if (w.is_empty()) {
//             w.kind = std::ascii::string(INKSCRIPTION_WRAPPER_KIND)
//         };
//         event::emit(Scribing {
//             id: object::id(w),
//             inks: ink.length(),
//         });
//         while (ink.length() > 0) {
//             vector::push_back(&mut w.items, *string::bytes(&ink.pop_back()));
//         };
//         ink.destroy_empty();
//     }
//
//     /// Event emitted when some ink is erased from the Wrapper.
//     public struct Erase has copy, drop {
//         id: ID,
//     }
//
//     /// Removes an ink inscription from the Wrapper at a specified index.
//     /// Ensures that the operation is type-safe and the index is within bounds.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `index`: Index of the inscription to remove.
//     /// Errors:
//     /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is not an inscription.
//     /// - `EIndexOutOfBounds`: If the index is out of bounds.
//     public entry fun erase(w: &mut Wrapper, index: u64) {
//         assert!(w.is_inkscription(), EWrapperNotEmptyOrInkSciption);
//         assert!(w.count() > index, EIndexOutOfBounds);
//         vector::remove(&mut w.items, index);
//         if (w.count() == 0) {
//             w.kind = std::ascii::string(EMPTY_WRAPPER_KIND)
//         };
//         event::emit(Erase {
//             id: object::id(w),
//         });
//     }
//
//     /// Shred all ink inscriptions in the Wrapper, effectively clearing it.
//     /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
//     /// Parameters:
//     /// - `w`: The Wrapper to be burned.
//     /// Errors:
//     /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is neither empty nor an ink inscription.
//     public entry fun shred(mut w: Wrapper) {
//         assert!(w.is_inkscription() || w.is_empty(), EWrapperNotEmptyOrInkSciption);
//         while (w.count() > 0) {
//             vector::pop_back(&mut w.items);
//         };
//         w.destroy_empty()
//     }
//
//
//     // =============== Object Extension Functions ===============
//
//     /// Represents a dynamic field key for an item in a Wrapper.
//     /// Each item in a Wrapper has a unique identifier of type ID.
//     public struct Item has store, copy, drop { id: ID }
//
//     // ===== Object Check functions =====
//
//     /// Checks if an item with the specified ID exists within the Wrapper and is of type T.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// - `id`: ID of the item to check.
//     /// Returns:
//     /// - True if the item exists and is of type T, false otherwise.
//     public fun has_item_with_type<T: key + store>(w: &Wrapper, id: ID): bool {
//         dof::exists_with_type<Item, T>(&w.id, Item { id }) && w.items.contains(&id.to_bytes()) && w.is_same_kind<T>()
//     }
//
//     // ===== Object property functions =====
//
//     #[syntax(index)]
//     /// Borrow an immutable reference to the item at a specified index within the Wrapper.
//     /// Ensures the item exists and is of type T before borrowing.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// - `i`: Index of the object to borrow.
//     /// Returns:
//     /// - Immutable reference to the item of type T.
//     /// Errors:
//     /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
//     public fun borrow<T: store + key>(w: &Wrapper, i: u64): &T {
//         let id = object::id_from_bytes(w.item(i));
//         assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
//         dof::borrow(&w.id, Item { id })
//     }
//
//     #[syntax(index)]
//     /// Borrow a mutable reference to the item at a specified index within the Wrapper.
//     /// Ensures the item exists and is of type T before borrowing.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `i`: Index of the object to borrow.
//     /// Returns:
//     /// - Mutable reference to the item of type T.
//     /// Errors:
//     /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
//     public fun borrow_mut<T: store + key>(w: &mut Wrapper, i: u64): &mut T {
//         let id = object::id_from_bytes(w.item(i));
//         assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
//         dof::borrow_mut(&mut w.id, Item { id })
//     }
//
//
//     // ===== Object Public Entry functions =====
//
//     /// Event emitted when an object is wrapped.
//     public struct Wraping has copy, drop {
//         id: ID,
//         kind: std::ascii::String,
//     }
//
//     /// Wraps object list into a new Wrapper.
//     /// Parameters:
//     /// - `w`: The Wrapper to unwrap.
//     /// - `object`: The object to wrap.
//     /// Returns:
//     /// - all objects of type T warp the Wrapper.
//     /// Errors:
//     /// - `EItemNotSameKind`: If any contained item is not of type T.
//     public entry fun wrap<T: store + key>(w: &mut Wrapper, mut objects: vector<T>) {
//         assert!(w.is_same_kind<T>(), EItemNotSameKind);
//         // add the object to the Wrapper
//         while (objects.length() > 0) {
//             w.add(objects.pop_back());
//         };
//         objects.destroy_empty();
//     }
//
//     /// TODO: USE THE INCEPTION WRAPPER TOKENIZED COIN TO UNWRAP
//     /// Unwraps all objects from the Wrapper, ensuring all are of type T, then destroys the Wrapper.
//     /// Parameters:
//     /// - `w`: The Wrapper to unwrap.
//     /// Returns:
//     /// - Vector of all objects of type T from the Wrapper.
//     /// Errors:
//     /// - `EItemNotSameKind`: If any contained item is not of type T.
//     public entry fun unwrap<T: store + key>(mut w: Wrapper, ctx: &mut TxContext) {
//         assert!(w.is_same_kind<T>(), EItemNotSameKind);
//         // unwrap all objects from the Wrapper
//         while (w.count() > 0) {
//             let id = object::id_from_bytes(w.item(0));
//             let object: T = dof::remove<Item, T>(&mut w.id, Item { id });
//             transfer::public_transfer(object, ctx.sender());
//             w.items.swap_remove(0);
//         };
//         // destroy the Wrapper
//         w.destroy_empty();
//     }
//
//     /// Event emitted when an object is added to the Wrapper.
//     public struct Adding has copy, drop {
//         id: ID,
//         object: ID,
//     }
//
//     /// Adds a single object to the Wrapper. If the Wrapper is empty, sets the kind based on the object's type.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `object`: The object to add to the Wrapper.
//     /// Effects:
//     /// - The object is added to the Wrapper, and its ID is stored.
//     /// Errors:
//     /// - `EItemNotSameKind`: If the Wrapper is not empty and the object's type does not match the Wrapper's kind.
//     public entry fun add<T: store + key>(w: &mut Wrapper, object: T) {
//         // check the object's kind
//         if (w.kind == std::ascii::string(EMPTY_WRAPPER_KIND)) {
//             w.kind = type_name::into_string(type_name::get<T>())
//         } else {
//             assert!(w.is_same_kind<T>(), EItemNotSameKind)
//         };
//         event::emit(Adding {
//             id: object::id(w),
//             object: object::id(&object),
//         });
//         // add the object to the Wrapper
//         let oid = object::id(&object);
//         dof::add(&mut w.id, Item { id: oid }, object);
//         w.items.push_back(oid.to_bytes());
//     }
//
//     /// Transfers all objects from one Wrapper (`self`) to another (`w`).
//     /// Both Wrappers must contain items of the same type T.
//     /// Parameters:
//     /// - `self`: Mutable reference to the source Wrapper.
//     /// - `w`: Mutable reference to the destination Wrapper.
//     /// Effects:
//     /// - Objects are moved from the source to the destination Wrapper.
//     /// - The source Wrapper is left empty after the operation.
//     /// Errors:
//     /// - `EItemNotSameKind`: If the Wrappers do not contain the same type of items.
//     public entry fun shift<T: store + key>(self: &mut Wrapper, w: &mut Wrapper) {
//         assert!(self.is_same_kind<T>(), EItemNotSameKind);
//         while (self.count() > 0) {
//             w.add(self.remove<T>(0));
//         };
//     }
//
//     // ===== Object Internal functions =====
//
//     /// Event emitted when an object is removed from the Wrapper.
//     public struct Removes has copy, drop {
//         id: ID,
//         object: ID,
//     }
//
//     /// Removes an object from the Wrapper at a specified index and returns it.
//     /// Checks that the operation is type-safe.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `i`: Index of the item to remove.
//     /// Returns:
//     /// - The object of type T removed from the Wrapper.
//     /// Effects:
//     /// - If the Wrapper is empty after removing the item, its kind is set to an empty string.
//     /// Errors:
//     /// - `EItemNotSameKind`: If the item type does not match the Wrapper's kind.
//     public(package) fun remove<T: store + key>(w: &mut Wrapper, i: u64): T {
//         assert!(w.count() > i, EIndexOutOfBounds);
//         assert!(w.is_same_kind<T>(), EItemNotSameKind);
//         // remove the item from the Wrapper
//         let id = object::id_from_bytes(w.item(i));
//         let object: T = dof::remove<Item, T>(&mut w.id, Item { id });
//         w.items.swap_remove(i);
//         // if the Wrapper is empty, set the kind to empty
//         if (w.count() == 0) {
//             w.kind = std::ascii::string(EMPTY_WRAPPER_KIND)
//         };
//         event::emit(Removes {
//             id: object::id(w),
//             object: object::id(&object),
//         });
//         object
//     }
//
//     /// Removes and returns a single object from the Wrapper by its ID.
//     /// Ensures the object exists and is of type T.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `id`: ID of the object to remove.
//     /// Returns:
//     /// - The object of type T.
//     /// Errors:
//     /// - `EItemNotFound`: If no item with the specified ID exists.
//     public(package) fun take<T: store + key>(w: &mut Wrapper, id: ID): T {
//         assert!(w.has_item_with_type<T>(id), EItemNotFound);
//         // remove the item from the Wrapper
//         let (has_item, index) = w.items.index_of(&id.to_bytes());
//         if (has_item) {
//             w.remove(index)
//         }else {
//             abort EItemNotFound
//         }
//     }
//
//     // ===== Object Public functions =====
//
//     /// Merges two Wrappers into one. If both Wrappers are of the same kind, merges the smaller into the larger.
//     /// If they are of different kinds or if one is empty, handles accordingly.
//     /// If the two Wrappers have the same kind, merge the less Wrapper into the greater Wrapper.
//     /// Otherwise, create a new Wrapper and add the two Wrappers.
//     /// If the two Wrappers are empty, return an empty Wrapper.
//     /// If one Wrapper is empty, return the other Wrapper.
//     /// Parameters:
//     /// - `w1`: First Wrapper to merge.
//     /// - `w2`: Second Wrapper to merge.
//     /// - `ctx`: Transaction context.
//     /// Returns:
//     /// - A single merged Wrapper.
//     /// Errors:
//     /// - `EItemNotSameKind`: If the Wrappers contain different kinds of items and cannot be merged.
//     public fun merge<T: store + key>(mut w1: Wrapper, mut w2: Wrapper, ctx: &mut TxContext): Wrapper {
//         let kind = type_name::into_string(type_name::get<T>());
//         // if one of the Wrappers is empty, return the other Wrapper
//         if (w1.is_empty()) {
//             w1.destroy_empty();
//             w2
//         } else if (w2.is_empty()) {
//             w2.destroy_empty();
//             w1
//         } else if (w1.kind == w2.kind && w2.kind == kind) {
//             // check the count of the two Wrappers
//             if (w1.count() > w2.count()) {
//                 w2.shift<T>(&mut w1);
//                 w2.destroy_empty();
//                 w1
//             } else {
//                 w1.shift<T>(&mut w2);
//                 w1.destroy_empty();
//                 w2
//             }
//         } else {
//             // create a new Wrapper
//             let mut w = new(ctx);
//             w.add(w1);
//             w.add(w2);
//             w
//         }
//     }
//
//     /// Splits objects from the Wrapper based on the specified list of IDs, moving them into a new Wrapper.
//     /// Parameters:
//     /// - `w`: Mutable reference to the original Wrapper.
//     /// - `ids`: Vector of IDs indicating which items to split.
//     /// - `ctx`: Transaction context.
//     /// Returns:
//     /// - A new Wrapper containing the split items.
//     /// Errors:
//     /// - `EItemNotFoundOrNotSameKind`: If any specified ID does not exist or the item is not of the expected type.
//     public fun split<T: store + key>(w: &mut Wrapper, mut ids: vector<ID>, ctx: &mut TxContext): Wrapper {
//         // create a new Wrapper
//         let mut w2 = new(ctx);
//         // take the objects from the first Wrapper and add them to the second Wrapper
//         while (ids.length() > 0) {
//             assert!(w.has_item_with_type<T>(ids[ids.length() - 1]), EItemNotFoundOrNotSameKind);
//             w2.add(w.take<T>(ids.pop_back()));
//         };
//         ids.destroy_empty();
//         w2
//     }
//
//     // =============== Tokenized Extension Functions ===============
//
//     /// Represents a lock for a tokenized object.
//     public struct Lock has store {
//         id: ID,
//         total_supply: u64,
//         owner: Option<address>,
//         fund: Balance<SUI>,
//     }
//
//     // === Tokenized Public Check Functions ===
//
//     /// Asserts that the given wrapper is tokenized.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Errors:
//     /// - `ENOT_TOKENIZED_WRAPPER`: If the wrapper is not tokenized.
//     public fun is_tokenized(w: &Wrapper) {
//         assert!(w.kind == std::ascii::string(TOKENIZED_WRAPPER_KIND), ENOT_TOKENIZED_WRAPPER);
//     }
//
//     /// Asserts that the given wrapper has the specified wrapper item.
//     /// Parameters:
//     /// - `wt`: Reference to the Wrapper.
//     /// - `id`: ID of the item to check.
//     /// Errors:
//     /// - `EWRAPPER_TOKENIZED_NOT_TOKENIZED`: If the wrapper does not contain the specified item.
//     public fun has_wrapper(wt: &Wrapper, id: ID) {
//         is_tokenized(wt);
//         assert!(
//             dof::exists_with_type<Item, Wrapper>(&wt.id, Item { id }) && vector::contains<vector<u8>>(
//                 &wt.items,
//                 &id.to_bytes()
//             ),
//             EWRAPPER_TOKENIZED_NOT_TOKENIZED
//         );
//     }
//
//     /// Asserts that the given wrapper does not have the specified wrapper item.
//     /// Parameters:
//     /// - `wt`: Reference to the Wrapper.
//     /// - `id`: ID of the item to check.
//     /// Errors:
//     /// - `EWRAPPER_TOKENIZED_HAS_TOKENIZED`: If the wrapper contains the specified item.
//     public fun not_wrapper(wt: &Wrapper, id: ID) {
//         is_tokenized(wt);
//         assert!(
//             !dof::exists_with_type<Item, Wrapper>(&wt.id, Item { id }) && vector::contains<vector<u8>>(
//                 &wt.items,
//                 &id.to_bytes()
//             ),
//             EWRAPPER_TOKENIZED_HAS_TOKENIZED
//         );
//     }
//
//     /// Asserts that the caller has access to the wrapper.
//     /// Parameters:
//     /// - `wt`: Reference to the Wrapper.
//     /// - `ctx`: Reference to the transaction context.
//     /// Errors:
//     /// - `EWRAPPER_TOKENIZED_NOT_ACCESS`: If the caller does not have access.
//     public fun has_access(wt: &Wrapper, ctx: &TxContext) {
//         is_tokenized(wt);
//         let lock = df::borrow<Item, Lock>(&wt.id, Item { id: object::id(wt) });
//         assert!(lock.owner.is_some() && ctx.sender() == lock.owner.borrow(), EWRAPPER_TOKENIZED_NOT_ACCESS)
//     }
//
//     // ===== Tokenized Public Entry functions =====
//
//     /// Event emitted when a tokenized object is created.
//     public struct Tokenization<phantom T: drop> has copy, drop {
//         id: ID,
//         object: ID,
//         treasury: ID,
//         supply: u64,
//         deposit: u64,
//     }
//
//     /// Tokenizes the given object with the specified treasury.
//     /// Treasury may be used to mint new tokens, and the object may be locked to prevent further minting.
//     /// there can fund the sui, and lock the object, and the owner can be withdraw the fund.
//     /// Parameters:
//     /// - `treasury`: Treasury capability representing the total supply.
//     /// - `total_supply`: Total supply amount.
//     /// - `o`: Object ID.
//     /// - `sui`: Coin of SUI.
//     /// - `wrapper`: Mutable reference to the Wrapper.
//     /// - `ctx`: Mutable reference to the transaction context.
//     /// Errors:
//     /// - `ETOKEN_SUPPLY_MISMATCH`: If the treasury's total supply is greater than the input total supply.
//     public entry fun tokenized<T: drop>(
//         treasury: TreasuryCap<T>,
//         o: ID,
//         total_supply: u64,
//         mut sui: Coin<SUI>,
//         ctx: &mut TxContext
//     ) {
//         assert!(sui.value() >= 2 * SUI_MIST_PER_SUI, EINVALID_SUI_VALUE);
//
//         // locked treasury total supply must smaller than input total_supply
//         assert!(treasury.total_supply() <= total_supply, ETOKEN_SUPPLY_MISMATCH);
//
//         // create a new tokenized object wrapper
//         let mut wt = new(ctx);
//         wt.kind = std::ascii::string(TOKENIZED_WRAPPER_KIND);
//         wt.alias = std::string::from_ascii(type_name::get_module(&type_name::get<T>()));
//
//         // some id
//         let tid = object::id(&treasury);
//         let wtid = object::id(&wt);
//
//         // emit event
//         event::emit(Tokenization<T> {
//             id: wtid,
//             object: o,
//             treasury: tid,
//             supply: total_supply,
//             deposit: sui.value()
//         });
//
//         // core internal
//         let vault = coin::split<SUI>(&mut sui, 2 * SUI_MIST_PER_SUI, ctx);
//         // TODO
//         public_transfer(vault, INCEPTION_WRAPPER_OBJECT_ID);
//         df::add(&mut wt.id,
//             Item { id: wtid },
//             Lock {
//                 id: o,
//                 owner: option::some(ctx.sender()),
//                 total_supply: total_supply,
//                 fund: sui.into_balance()
//             }
//         );
//         // add items ,but not dof add item,means not add to the object store
//         wt.items.push_back(o.to_bytes());
//         // dof::add(&mut wt.id, Item{ id: oid }, wrapper_tokenized);
//
//         // add treasury,means the treasury is in the object store
//         wt.items.push_back(tid.to_bytes());
//         dof::add(&mut wt.id, Item { id: tid }, treasury);
//
//         // share the tokenized wrapper with the treasury
//         transfer::public_share_object(wt);
//     }
//
//     #[lint_allow(self_transfer)]
//     /// Detokenizes a tokenized wrapper.
//     /// Parameters:
//     /// - `wt`: Mutable reference to the Wrapper.
//     /// - `ctx`: Mutable reference to the transaction context.
//     /// Errors:
//     /// - `EWRAPPER_TOKENIZED_NOT_ACCESS`: If the caller does not have access.
//     public entry fun detokenized<T: drop>(mut wt: Wrapper, ctx: &mut TxContext) {
//         // check has access
//         has_access(&wt, ctx);
//
//         // transfer treasury to sender
//         let treasury_id = object::id_from_bytes(wt.item(1));
//         let treasury: TreasuryCap<T> = dof::remove<Item, TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
//         transfer::public_transfer(treasury, tx_context::sender(ctx));
//
//         // transfer fund to sender and delete Lock
//         let wtid = object::id(&wt);
//         let Lock { id: _, owner: _, total_supply: _, fund } = df::remove<Item, Lock>(&mut wt.id, Item { id: wtid });
//         transfer::public_transfer(coin::from_balance<SUI>(fund, ctx), tx_context::sender(ctx));
//
//         // delete the tokenized object wrapper
//         wt.items.swap_remove(0);
//         wt.items.swap_remove(0);
//         wt.destroy_empty();
//     }
//
//     /// Event emitted when stocking additional funds into a tokenized object wrapper.
//     public struct Stocking has copy, drop {
//         id: ID,
//         value: u64,
//         fund: u64,
//     }
//
//     /// Stocks additional funds into a tokenized object wrapper.
//     /// Parameters:
//     /// - `wt`: Mutable reference to the Wrapper.
//     /// - `sui`: Coin of SUI.
//     /// - `ctx`: Mutable reference to the transaction context.
//     public entry fun stocking(wt: &mut Wrapper, sui: Coin<SUI>, ctx: &mut TxContext) {
//         is_tokenized(wt);
//         let wtid = object::id(wt);
//         let mut lock = df::borrow_mut<Item, Lock>(&mut wt.id, Item { id: wtid });
//         let value = sui.value();
//         lock.fund.join<SUI>(sui.into_balance());
//         event::emit(Stocking {
//             id: wtid,
//             value: value,
//             fund: lock.fund.value()
//         });
//     }
//
//     /// Event emitted when withdrawing funds from a tokenized object wrapper.
//     public struct Withdraw has copy, drop {
//         id: ID,
//         value: u64,
//         fund: u64,
//     }
//
//     /// Withdraws funds from a tokenized object wrapper.
//     /// Parameters:
//     /// - `wt`: Mutable reference to the Wrapper.
//     /// - `value`: Amount of funds to withdraw.
//     /// - `ctx`: Mutable reference to the transaction context.
//     /// Errors:
//     /// - `EINSUFFICIENT_BALANCE`: If the wrapper's fund balance is less than the requested withdrawal amount.
//     #[lint_allow(self_transfer)]
//     public entry fun withdraw(wt: &mut Wrapper, value: u64, ctx: &mut TxContext) {
//         // Ensure the wrapper is tokenized
//         is_tokenized(wt);
//         // Ensure the caller has access to the wrapper
//         has_access(wt, ctx);
//         // Get the wrapper ID
//         let wtid = object::id(wt);
//         // Borrow the lock mutably from the data frame
//         let mut lock = df::borrow_mut<Item, Lock>(&mut wt.id, Item { id: wtid });
//         // Check if the wrapper's fund balance is sufficient for the withdrawal
//         assert!(lock.fund.value() >= value, EINSUFFICIENT_BALANCE);
//         // Split the specified amount from the fund
//         let c = coin::from_balance<SUI>(lock.fund.split<SUI>(value), ctx);
//         event::emit(Withdraw {
//             id: wtid,
//             value: value,
//             fund: lock.fund.value()
//         });
//         // Transfer the withdrawn funds to the sender
//         transfer::public_transfer(c, ctx.sender());
//     }
//
//     /// Event emitted when locking a tokenized object wrapper.
//     public struct Locking has copy, drop {
//         id: ID,
//         sender: address,
//         withdraw: u64,
//     }
//
//     #[lint_allow(self_transfer)]
//     /// Locks the given wrapper with the specified total supply.
//     /// Lock the wrapper with the total supply, and transfer the SUI fund to the sender.
//     /// Parameters:
//     /// - `wt`: Mutable reference to the Wrapper.
//     /// - `o`: The Wrapper to lock.
//     /// - `ctx`: Mutable reference to the transaction context.
//     public entry fun lock(wt: &mut Wrapper, o: Wrapper, ctx: &mut TxContext) {
//         // check if wrapper is not locked,must be none
//         not_wrapper(wt, object::id(&o));
//         // fill the lock owner and total_supply
//         let wtid = object::id(wt);
//         let mut lock = df::borrow_mut<Item, Lock>(&mut wt.id, Item { id: wtid });
//         // fill the owner
//         option::fill(&mut lock.owner, ctx.sender());
//         event::emit(Locking {
//             id: wtid,
//             sender: ctx.sender(),
//             withdraw: lock.fund.value()
//         });
//         // withdraw SUI fund to the sender
//         transfer::public_transfer(coin::from_balance<SUI>(balance::withdraw_all(&mut lock.fund), ctx), ctx.sender());
//         // fill the wrapper and owner
//         dof::add(&mut wt.id, Item { id: object::id(&o) }, o);
//     }
//
//     #[lint_allow(self_transfer)]
//     /// Unlocks the given wrapper.
//     /// Unlocks the wrapper by burning the total supply of the tokenized wrapper and transferring the ownership of the locked wrapper to the sender.
//     /// The total supply must match the treasury supply, and the total supply must be zero.
//     /// If user lock wrapper to withdraw the SUI, the hacker must burn all the token to unlock the wrapper.
//     /// So user can reserve the token,avoid the hacker to withdraw the SUI,and unlock the wrapper.
//     /// Parameters:
//     /// - `wt`: Mutable reference to the Wrapper.
//     /// - `ctx`: Mutable reference to the transaction context.
//     /// Errors:
//     /// - `ETOKEN_SUPPLY_MISMATCH`: If the total supply does not match the treasury supply.
//     /// - `ECANNOT_UNLOCK_NON_ZERO_SUPPLY`: If the total supply is not zero.
//     public entry fun unlock<T: drop>(mut wt: Wrapper, ctx: &mut TxContext) {
//         // check has access
//         has_access(&wt, ctx);
//         // burn total supply of tokenized wrapper to unlock wrapper
//         let total_supply = total_supply(&wt);
//         let treasury_supply = treasury_supply<T>(&wt);
//         assert!(total_supply == treasury_supply, ETOKEN_SUPPLY_MISMATCH);
//         assert!(total_supply == 0, ECANNOT_UNLOCK_NON_ZERO_SUPPLY);
//
//         // transfer locked wrapper ownership to sender
//         let object_id = object::id_from_bytes(wt.item(0));
//         has_wrapper(&wt, object_id);
//         let object: Wrapper = dof::remove<Item, Wrapper>(&mut wt.id, Item { id: object_id });
//         transfer::public_transfer(object, tx_context::sender(ctx));
//
//         // detokenized the wrapper
//         detokenized<T>(wt, ctx);
//     }
//
//     /// Mints new tokens for the given wrapper.
//     /// Parameters:
//     /// - `wt`: Mutable reference to the Wrapper.
//     /// - `value`: Amount of tokens to mint.
//     /// - `ctx`: Mutable reference to the transaction context.
//     /// Errors:
//     /// - `ETOKEN_SUPPLY_MISMATCH`: If the value to mint exceeds the maximum supply.
//     public entry fun mint<T: drop>(wt: &mut Wrapper, value: u64, ctx: &mut TxContext) {
//         // check has access
//         has_access(wt, ctx);
//
//         // check if total supply is less than max supply
//         let total_supply = total_supply(wt);
//         let treasury_supply = treasury_supply<T>(wt);
//         assert!(value + treasury_supply <= total_supply, ETOKEN_SUPPLY_MISMATCH);
//
//         // mint token
//         let treasury_id = object::id_from_bytes(wt.item(1));
//         let mut treasury = dof::borrow_mut<Item, TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
//         let token = coin::mint(treasury, value, ctx);
//
//         // transfer token to owner
//         transfer::public_transfer(token, tx_context::sender(ctx));
//     }
//
//     /// Burns tokens from the given wrapper.
//     /// Parameters:
//     /// - `wt`: Mutable reference to the Wrapper.
//     /// - `c`: The Coin to burn.
//     public entry fun burn<T: drop>(wt: &mut Wrapper, c: Coin<T>) {
//         is_tokenized(wt);
//         // burn token
//         let treasury_id = object::id_from_bytes(wt.item(1));
//         let burn_value = c.value();
//         let mut treasury = dof::borrow_mut<Item, TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
//         coin::burn(treasury, c);
//
//         // update total supply
//         let wtid = object::id(wt);
//         let mut lock = df::borrow_mut<Item, Lock>(&mut wt.id, Item { id: wtid });
//         lock.total_supply = lock.total_supply - burn_value;
//     }
//
//     /// Gets the total supply of the tokenized wrapper.
//     /// Parameters:
//     /// - `wt`: Reference to the Wrapper.
//     /// Returns:
//     /// - The total supply.
//     public fun total_supply(wt: &Wrapper): u64 {
//         is_tokenized(wt);
//         let lock = df::borrow<Item, Lock>(&wt.id, Item { id: object::id(wt) });
//         lock.total_supply
//     }
//
//     /// Gets the current supply of the treasury.
//     /// Parameters:
//     /// - `wt`: Reference to the Wrapper.
//     /// Returns:
//     /// - The current supply.
//     public fun treasury_supply<T: drop>(wt: &Wrapper): u64 {
//         is_tokenized(wt);
//         let treasury_id = object::id_from_bytes(wt.item(1));
//         let treasury = dof::borrow<Item, TreasuryCap<T>>(&wt.id, Item { id: treasury_id });
//         treasury.total_supply()
//     }
//
//
//     // =============== Vesting Extension Functions ===============
//
//     public struct VestingLock<phantom T> has store {
//         id: ID,
//         initial: Balance<T>,
//         // 初始释放
//         vesting: Balance<T>,
//         //缓慢释放
//         claimed: u64,
//         //已经提取的周期数
//     }
//
//     public struct Vesting<phantom T> has copy, drop, store {
//         cliff: u64,
//         // Vesting计划的Cliff悬崖期限
//         vesting: u64,
//         // Vesting计划的总的Vesting期限
//         initial: u64,
//         // 初始释放万分比
//         cycle: u64,
//         // 释放周期，直接以秒为单位,可以设置天,月,年
//         start: u64,
//         // 开始时间
//     }
//
//     public fun is_vesting(w: &Wrapper): bool {
//         w.kind == std::ascii::string(VESTING_WRAPPER_KIND)
//     }
//
//     fun vesting_id<T>(vesting: &Vesting<T>): ID {
//         let mut v_bcs = bcs::to_bytes(vesting);
//         vector::append(&mut v_bcs, bcs::to_bytes(&type_name::get<T>()));
//         object::id_from_bytes(blake2b256(&v_bcs))
//     }
//
//     public entry fun vesting<T>(w: &mut Wrapper, start: u64, initial: u64, cliff: u64, vesting: u64, cycle: u64) {
//         assert!(w.is_vesting() || w.is_empty(), EWrapperNotEmptyOrVesting);
//         assert!(cycle >= 86_400_000, ECycleMustBeAtLeastOneDay); // 确保周期至少为一天
//         assert!(cycle % 86_400_000 == 0, ECycleMustBeMultipleOfDay); // 确保周期是一天毫秒数的倍数
//         assert!(initial <= 10_000, EInitialExceedsLimit);
//         assert!(start >= VESTING_DEPLOY_TIME_MS, EStartExceedsLimit);
//         assert!(vesting >= cliff, EVestingCycleMustGTECliffCycle);
//
//         let wvid = object::id(w);
//         if (w.kind == std::ascii::string(EMPTY_WRAPPER_KIND)) {
//             w.kind = std::ascii::string(VESTING_WRAPPER_KIND);
//             df::add(&mut w.id, Item { id: wvid }, Vesting<T> { start, initial, cliff, vesting, cycle });
//         }else if (w.is_empty() && w.is_vesting()) {
//             assert!(df::exists_(&w.id, Item { id: wvid }), EVestingWrapperNotVestingType);
//             let vesting_type: &mut Vesting<T> = df::borrow_mut(&mut w.id, Item { id: wvid });
//             vesting_type.start = start;
//             vesting_type.initial = initial;
//             vesting_type.cliff = cliff;
//             vesting_type.vesting = vesting;
//             vesting_type.cycle = cycle;
//         }else {
//             abort EVestingWrapperHasRelease
//         }
//     }
//
//     public entry fun release<T>(w: &mut Wrapper, c: Coin<T>) {
//         assert!(w.is_vesting() && w.is_empty(), EVestingWrapperHasRelease);
//         assert!(c.value() > 0, EInvalidReleaseAmount);
//         let vtype = df::borrow<Item, Vesting<T>>(&w.id, Item { id: object::id(w) });
//         // 最大支持190万亿的balance输入
//         let initial_balance = (vtype.initial * c.value() * 10) / (10000 * 10);
//
//         // update state
//         let vid = vesting_id(vtype);
//         w.items.push_back(vid.to_bytes());
//         let mut vesting_balance = c.into_balance<T>();
//         let vesing_lock = VestingLock {
//             id: vid,
//             initial: balance::split<T>(&mut vesting_balance, initial_balance),
//             vesting: vesting_balance,
//             claimed: 0
//         };
//         df::add(&mut w.id, Item { id: vid }, vesing_lock);
//     }
//
//
//     public fun amount<T>(w: &Wrapper): u64 {
//         assert!(w.is_vesting() && !w.is_empty(), EWrapperNotReleaseVesting);
//         let vesting_lock = df::borrow<Item, VestingLock<T>>(
//             &w.id,
//             Item { id: object::id_from_bytes(w.item(0)) }
//         );
//         vesting_lock.vesting.value() + vesting_lock.initial.value()
//     }
//
//
//     public entry fun revoke<T>(mut w: Wrapper) {
//         assert!(w.is_vesting() && !w.is_empty(), EWrapperNotReleaseVesting);
//         assert!(w.amount<T>() == 0, EInvalidRevokeAmount);
//
//         let wid = object::id(&w);
//         let vtid = object::id_from_bytes(w.item(0));
//
//         // 如果已经释放完毕,设置为一个空的vesting
//         let VestingLock { id: _, initial, vesting, claimed: _ } = df::remove<Item, VestingLock<T>>(
//             &mut w.id,
//             Item { id: vtid }
//         );
//         balance::destroy_zero(initial);
//         balance::destroy_zero(vesting);
//
//         let Vesting { cliff: _, vesting: _, initial: _, cycle: _, start: _ } = df::remove<Item, Vesting<T>>(
//             &mut w.id,
//             Item { id: wid }
//         );
//         w.items.pop_back();
//         w.items.pop_back();
//         w.destroy_empty();
//     }
//
//     // 分割 vesting
//     public fun separate<T>(w: &mut Wrapper, amount: u64, ctx: &mut TxContext): Wrapper {
//         assert!(w.is_vesting() && !w.is_empty(), EWrapperNotReleaseVesting);
//         let total_value = w.amount<T>();
//         assert!(amount < total_value, EInvalidSeparateAmount);
//
//         // create a new vesting
//         let vtype = df::borrow<Item, Vesting<T>>(&w.id, Item { id: object::id(w) });
//         let mut new_wrapper = new(ctx);
//         vesting<T>(&mut new_wrapper, vtype.start, vtype.initial, vtype.cliff, vtype.vesting, vtype.cycle);
//
//         // get old vesting_lock
//         let vtid = object::id_from_bytes(w.item(0));
//         let mut vesting_lock = df::borrow_mut<Item, VestingLock<T>>(&mut w.id, Item { id: vtid });
//
//         // create a separate balance and release
//         let mut separate_balance = balance::zero<T>();
//         let initial_split_amount = (vesting_lock.initial.value() * amount) / total_value;
//         balance::join(&mut separate_balance, balance::split(&mut vesting_lock.initial, initial_split_amount));
//         balance::join(&mut separate_balance, balance::split(&mut vesting_lock.vesting, amount - initial_split_amount));
//         release(&mut new_wrapper, coin::from_balance(separate_balance, ctx));
//         // update claimed
//         let mut new_vesting_lock = df::borrow_mut<Item, VestingLock<T>>(&mut new_wrapper.id, Item { id: vtid });
//         new_vesting_lock.claimed = vesting_lock.claimed;
//         new_wrapper
//     }
//
//     public entry fun claim<T>(mut w: Wrapper, clk: &Clock, ctx: &mut TxContext) {
//         assert!(w.is_vesting() && !w.is_empty(), EWrapperNotReleaseVesting);
//         let vtid = object::id_from_bytes(w.item(0));
//         let vtype = df::borrow<Item, Vesting<T>>(&w.id, Item { id: object::id(&w) });
//         let now = clock::timestamp_ms(clk);
//         assert!(now >= vtype.start, ECannotClaimBeforeStart);
//
//         // 提取必要的变量
//         let elapsed_periods = (now - vtype.start) / vtype.cycle;      // 计算已过的周期数
//         let cliff = vtype.cliff; // 提取cliff周期数
//         let vesting = vtype.vesting; // 提取vesting周期数
//         let mut vesting_lock = df::borrow_mut<Item, VestingLock<T>>(
//             &mut w.id,
//             Item { id: vtid }
//         );
//         // 创建一个提取balance
//         let mut claim_balance = balance::zero<T>();
//         // 计算下个周期应该释放的代币数量
//         let cycle_realse_balance = if ((vesting - vesting_lock.claimed) <= cliff) {
//             vesting_lock.vesting.value()
//         }else {
//             vesting_lock.vesting.value() / (vesting - cliff - vesting_lock.claimed)
//         };
//
//         // claim initial amount
//         if (vesting_lock.initial.value() > 0) {
//             claim_balance.join(vesting_lock.initial.withdraw_all());
//         };
//
//         // 如果具有有效可提取周期
//         if (elapsed_periods > cliff + vesting_lock.claimed) {
//             // 进行释放量计算
//             let should_release = cycle_realse_balance * (elapsed_periods - cliff - vesting_lock.claimed);
//             // 修改vesting_lock的已提取周期数
//             vesting_lock.claimed = elapsed_periods - cliff;
//             if (should_release > vesting_lock.vesting.value()) {
//                 // 代表应释放量大于了剩余释放量,直接全部提取
//                 claim_balance.join(vesting_lock.vesting.withdraw_all());
//             }else {
//                 //分割应释放量到提取balance中
//                 claim_balance.join(vesting_lock.vesting.split(should_release));
//             }
//         };
//
//         // do transfer and destroy
//         if (claim_balance.value() == 0) {
//             balance::destroy_zero<T>(claim_balance);
//         }else {
//             transfer::public_transfer(coin::from_balance(claim_balance, ctx), ctx.sender());
//         };
//         if (w.amount<T>() == 0) {
//             w.revoke<T>();
//         }else {
//             transfer::public_transfer(w, ctx.sender());
//         }
//     }
//
//     fun sync_claim<T>(vtype: &Vesting<T>, v1: &mut VestingLock<T>, v2: &mut VestingLock<T>) {
//         assert!(v1.claimed > v2.claimed, EInvalidVestingSyncCall);
//         // 差距轮次
//         let claimed_gap = v1.claimed - v2.claimed;
//
//         // 计算w2下个周期应该释放的代币数量
//         let cycle_realse_balance = if ((vtype.vesting - v2.claimed) <= vtype.cliff) {
//             v2.vesting.value()
//         }else {
//             v2.vesting.value() / (vtype.vesting - vtype.cliff - v2.claimed)
//         };
//
//         // vesting 部分同步释放
//         let sync_release_amount = cycle_realse_balance * claimed_gap;
//         // 修改vesting_lock的已提取周期数
//         v2.claimed = v1.claimed;
//         v2.initial.join(
//             if (sync_release_amount > v2.vesting.value()) {
//                 // 代表应释放量大于了剩余释放量,直接全部提取
//                 v2.vesting.withdraw_all()
//             }else {
//                 //分割应释放量到提取balance中
//                 v2.vesting.split(sync_release_amount)
//             }
//         );
//     }
//
//     //   合并 vesting
//     public fun combine<T>(mut w1: Wrapper, mut w2: Wrapper, ctx: &mut TxContext): Wrapper {
//         assert!(w1.is_vesting() && w2.is_vesting(), EWrapperNotVesting);
//         assert!(w1.item(0) == w2.item(0), EVestingNotSameKind);
//         let vtype = *df::borrow<Item, Vesting<T>>(&w1.id, Item { id: object::id_from_bytes(w1.item(0)) });
//         // if one of the Vesting is zero, return the other Wrapper
//         if (w1.amount<T>() == 0) {
//             w1.revoke<T>();
//             w2
//         } else if (w2.amount<T>() == 0) {
//             w2.revoke<T>();
//             w1
//         } else {
//             // 获取最大提取周期的那个值
//             let vtid = object::id_from_bytes(w1.item(0));
//             let mut w1_vesting_lock = df::borrow_mut<Item, VestingLock<T>>(&mut w1.id, Item { id: vtid });
//             let mut w2_vesting_lock = df::borrow_mut<Item, VestingLock<T>>(&mut w2.id, Item { id: vtid });
//             if (w1_vesting_lock.claimed == w2_vesting_lock.claimed) {
//                 w1_vesting_lock.vesting.join(w2_vesting_lock.vesting.withdraw_all());
//                 w1_vesting_lock.initial.join(w2_vesting_lock.initial.withdraw_all());
//                 w2.revoke<T>();
//                 w1
//             }else {
//                 if (w1_vesting_lock.claimed > w2_vesting_lock.claimed) {
//                     sync_claim(&vtype, w1_vesting_lock, w2_vesting_lock);
//                     w1_vesting_lock.vesting.join(w2_vesting_lock.vesting.withdraw_all());
//                     w1_vesting_lock.initial.join(w2_vesting_lock.initial.withdraw_all());
//                     w2.revoke<T>();
//                     w1
//                 }else {
//                     sync_claim(&vtype, w2_vesting_lock, w1_vesting_lock);
//                     w2_vesting_lock.vesting.join(w1_vesting_lock.vesting.withdraw_all());
//                     w2_vesting_lock.initial.join(w1_vesting_lock.initial.withdraw_all());
//                     w1.revoke<T>();
//                     w2
//                 }
//             }
//         }
//     }
//
//     // =============== Account Extension Functions ===============
//     public fun is_vault(w: &Wrapper):bool {
//         w.kind == std::ascii::string(VAULT_WRAPPER_KIND)
//     }
//
//     public struct CurrencyVault<phantom T> has copy, drop, store {}
//
//     public struct AssetVault<phantom T> has copy, drop, store { id: ID }
//
//     public entry fun acquire<T: key + store>(w: &mut Wrapper, assert: Receiving<T>) {
//         assert!(w.is_empty() || w.is_vault(), EWrapperNotEmptyOrVault);
//         let sent_assert = transfer::public_receive(&mut w.id, assert);
//         if (w.is_empty()) {
//             w.kind = ascii::string(VAULT_WRAPPER_KIND);
//         };
//         let assert_id = object::id(&sent_assert);
//         let assert_type = AssetVault<T> { id: assert_id };
//         let wid = &mut w.id;
//         w.items.push_back(assert_id.id_to_bytes());
//         dof::add(wid, assert_type, sent_assert);
//     }
//
//     public entry fun receipts<T>(w: &mut Wrapper, currency: Receiving<Coin<T>>) {
//         assert!(w.is_empty() || w.is_vault(), EWrapperNotEmptyOrVault);
//         let coin = transfer::public_receive(&mut w.id, currency);
//         if (w.is_empty()) {
//             w.kind = ascii::string(VAULT_WRAPPER_KIND);
//         };
//         let balance_type = CurrencyVault<T> {};
//         let wid = &mut w.id;
//         if (df::exists_(wid, balance_type)) {
//             let balance: &mut Coin<T> = df::borrow_mut(wid, balance_type);
//             coin::join(balance, coin);
//         } else {
//             w.items.push_back(object::id(&coin).id_to_bytes());
//             df::add(wid, balance_type, coin);
//         }
//     }
//
//     /// 提取资产的函数
//     public entry fun extract<T: key + store>(w: &mut Wrapper, asset_id: ID, ctx: &mut TxContext) {
//         // 确保 Wrapper 是空的或类型是 Vault
//         assert!(w.is_empty() || w.is_vault(), EWrapperNotEmptyOrVault);
//         assert!(vector::contains(&w.items, &asset_id.id_to_bytes()), EAssetNotFoundInVault);
//
//         // 检查资产是否存在于 Wrapper 中
//         let asset_type = AssetVault<T> { id: asset_id };
//         let wid = &mut w.id;
//         assert!(dof::exists_(wid, asset_type), EAssetNotFoundInVault);
//
//         // 转移资产到请求者
//         let asset = dof::remove<AssetVault<T>, T>(wid, asset_type);
//         transfer::public_transfer(asset, ctx.sender());
//         // 从 Wrapper 中移除资产
//         let (_, index) = vector::index_of(&w.items, &asset_id.id_to_bytes());
//         w.items.swap_remove(index);
//     }
//
//     /// 提取货币的函数
//     public entry fun retrieve<T: key + store>(w: &mut Wrapper, amount: u64, ctx: &mut TxContext) {
//         // 确保 Wrapper 是空的或类型是 Vault
//         assert!(w.is_empty() || w.is_vault(), EWrapperNotEmptyOrVault);
//
//         // 检查余额是否存在
//         let balance_type = CurrencyVault<T> {};
//         let wid = &mut w.id;
//         assert!(df::exists_(wid, balance_type), ECurrencyNotFoundInVault);
//
//         // 获取当前余额并确保有足够的资金
//         let balance: &mut Coin<T> = df::borrow_mut(wid, balance_type);
//         assert!(coin::value(balance) >= amount, ECurrencyNotEnoughFoundInVault);
//
//         // 分割并移除指定数量的货币
//         let coin_to_retrieve = coin::split(balance, amount, ctx);
//         if (coin::value(balance) == 0) {
//             let currency = df::remove<CurrencyVault<T>, Coin<T>>(wid, balance_type);
//             let (has, index) = vector::index_of(&w.items, &object::id(&currency).id_to_bytes());
//             assert!(has, ECurrencyNotFoundInVault);
//             w.items.swap_remove(index);
//             coin::destroy_zero(currency);
//         };
//         // 转移货币到请求者
//         transfer::public_transfer(coin_to_retrieve, ctx.sender());
//     }
// }