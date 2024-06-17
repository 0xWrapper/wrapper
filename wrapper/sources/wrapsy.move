module wrapper::wrapsy {

    use std::type_name;
    use sui::event;
    use wrapper::wrapper::{Wrapper, new};

    // ===== Error Codes =====
    const EWrapperTakeInvalidItemOrKind: u64 = 0;
    const EWrapperRemoveInvalidItemIndex: u64 = 1;
    const EWrapperWrapAllowedEmptyOrSameKind: u64 = 2;
    const EWrapperUnwrapAllowedEmptyOrSameKind: u64 = 3;
    const EWrapperBorrowInvalidItemOrKind: u64 = 4;
    const EWrapperAddInvalidObjectKind: u64 = 5;
    const EWrapperShiftInvalidWrapperKind: u64 = 6;
    const EWrapperRemoveInvalidItemOrKind: u64 = 7;
    const EWrapperSplitInvalidItemsOrKind: u64 = 8;


    // =============== Object Extension Functions ===============

    /// Represents a dynamic field key for an item in a Wrapper.
    /// Each item in a Wrapper has a unique identifier of type ID.
    public struct Item has store, copy, drop { id: ID }

    // ===== Object Check functions =====

    /// Checks if the specified type T matches the kind of items stored in the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the type T matches the Wrapper's kind, false otherwise.
    public fun is_same_kind<T: key + store>(w: &Wrapper): bool {
        w.kind() == type_name::into_string(type_name::get<T>())
    }

    /// Checks if an item with the specified ID exists within the Wrapper and is of type T.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Returns:
    /// - True if the item exists and is of type T, false otherwise.
    public fun has_item_with_type<T: key + store>(w: &Wrapper, id: ID): bool {
        w.exists_object<Item, T>(Item { id }) && w.items().contains(&id.to_bytes()) && is_same_kind<T>(w)
    }

    // ===== Object property functions =====

    /// Borrow an immutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `i`: Index of the object to borrow.
    /// Returns:
    /// - Immutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow<T: store + key>(w: &Wrapper, i: u64): &T {
        let id = object::id_from_bytes(w.item(i));
        assert!(has_item_with_type<T>(w, id), EWrapperBorrowInvalidItemOrKind);
        w.borrow_object<Item, T>(Item { id })
    }

    /// Borrow a mutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `i`: Index of the object to borrow.
    /// Returns:
    /// - Mutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow_mut<T: store + key>(w: &mut Wrapper, i: u64): &mut T {
        let id = object::id_from_bytes(w.item(i));
        assert!(has_item_with_type<T>(w, id), EWrapperBorrowInvalidItemOrKind);
        w.mutate_object<Item, T>(Item { id })
    }


    // ===== Object Public Entry functions =====

    /// Event emitted when an object is wrapped.
    public struct Wraped has copy, drop {
        id: ID,
        kind: std::ascii::String,
    }

    /// Wraps object list into a new Wrapper.
    /// Parameters:
    /// - `w`: The Wrapper to unwrap.
    /// - `object`: The object to wrap.
    /// Returns:
    /// - all objects of type T warp the Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If any contained item is not of type T.
    public entry fun wrap<T: store + key>(w: &mut Wrapper, mut objects: vector<T>) {
        assert!(w.is_empty() || is_same_kind<T>(w), EWrapperWrapAllowedEmptyOrSameKind);
        // add the object to the Wrapper
        while (objects.length() > 0) {
            add(w, objects.pop_back());
        };
        event::emit(Wraped {
            id: object::id(w),
            kind: w.kind()
        });
        objects.destroy_empty();
    }


    /// Event emitted when an object is wrapped.
    public struct UnWraped has copy, drop {
        id: ID,
        kind: std::ascii::String,
    }

    /// TODO: USE THE INCEPTION WRAPPER TOKENIZED COIN TO UNWRAP
    /// Unwraps all objects from the Wrapper, ensuring all are of type T, then destroys the Wrapper.
    /// Parameters:
    /// - `w`: The Wrapper to unwrap.
    /// Returns:
    /// - Vector of all objects of type T from the Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If any contained item is not of type T.
    public entry fun unwrap<T: store + key>(mut w: Wrapper, ctx: &mut TxContext) {
        assert!(is_same_kind<T>(&w) || w.is_empty(), EWrapperUnwrapAllowedEmptyOrSameKind);
        // unwrap all objects from the Wrapper
        while (w.count() > 0) {
            let id = object::id_from_bytes(w.item(0));
            let object: T = w.remove_object<Item, T>(Item { id });
            transfer::public_transfer(object, ctx.sender());
            w.remove_item(0);
        };
        // destroy the Wrapper
        w.destroy_empty();
    }

    /// Event emitted when an object is added to the Wrapper.
    public struct Adding has copy, drop {
        id: ID,
        object: ID,
    }

    /// Adds a single object to the Wrapper. If the Wrapper is empty, sets the kind based on the object's type.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `object`: The object to add to the Wrapper.
    /// Effects:
    /// - The object is added to the Wrapper, and its ID is stored.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrapper is not empty and the object's type does not match the Wrapper's kind.
    public entry fun add<T: store + key>(w: &mut Wrapper, object: T) {
        // check the object's kind
        if (w.is_empty()) {
            w.set_kind(type_name::into_string(type_name::get<T>()));
        } else {
            assert!(is_same_kind<T>(w), EWrapperAddInvalidObjectKind)
        };
        event::emit(Adding {
            id: object::id(w),
            object: object::id(&object),
        });
        // add the object to the Wrapper
        let oid = object::id(&object);
        w.add_object(Item { id: oid }, object);
        w.add_item(oid.to_bytes());
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
    public entry fun shift<T: store + key>(self: &mut Wrapper, w: &mut Wrapper) {
        assert!(is_same_kind<T>(self), EWrapperShiftInvalidWrapperKind);
        while (self.count() > 0) {
            add(w, remove<T>(self, 0));
        };
    }

    // ===== Object Internal functions =====

    /// Event emitted when an object is removed from the Wrapper.
    public struct Removing has copy, drop {
        id: ID,
        object: ID,
    }

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
    public(package) fun remove<T: store + key>(w: &mut Wrapper, i: u64): T {
        assert!(w.count() > i, EWrapperRemoveInvalidItemIndex);
        assert!(is_same_kind<T>(w), EWrapperRemoveInvalidItemOrKind);
        // remove the item from the Wrapper
        let id = object::id_from_bytes(w.item(i));
        let object: T = w.remove_object<Item, T>(Item { id });
        w.remove_item(i);
        // if the Wrapper is empty, set the kind to empty
        event::emit(Removing {
            id: object::id(w),
            object: object::id(&object),
        });
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
    public(package) fun take<T: store + key>(w: &mut Wrapper, id: ID): T {
        assert!(has_item_with_type<T>(w, id), EWrapperTakeInvalidItemOrKind);
        // remove the item from the Wrapper
        let (has_item, index) = w.items().index_of(&id.to_bytes());
        if (has_item) {
            remove(w, index)
        }else {
            abort EWrapperTakeInvalidItemOrKind
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
    public fun merge<T: store + key>(mut w1: Wrapper, mut w2: Wrapper, ctx: &mut TxContext): Wrapper {
        let kind = type_name::into_string(type_name::get<T>());
        // if one of the Wrappers is empty, return the other Wrapper
        if (w1.is_empty()) {
            w1.destroy_empty();
            w2
        } else if (w2.is_empty()) {
            w2.destroy_empty();
            w1
        } else if (w1.kind() == w2.kind() && w2.kind() == kind) {
            // check the count of the two Wrappers
            if (w1.count() > w2.count()) {
                shift<T>(&mut w2, &mut w1);
                w2.destroy_empty();
                w1
            } else {
                shift<T>(&mut w1, &mut w2);
                w1.destroy_empty();
                w2
            }
        } else {
            // create a new Wrapper
            let mut w = new(ctx);
            add(&mut w, w1);
            add(&mut w, w2);
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
    public fun split<T: store + key>(w: &mut Wrapper, mut ids: vector<ID>, ctx: &mut TxContext): Wrapper {
        // create a new Wrapper
        let mut w2 = new(ctx);
        // take the objects from the first Wrapper and add them to the second Wrapper
        while (ids.length() > 0) {
            assert!(has_item_with_type<T>(w, ids[ids.length() - 1]), EWrapperSplitInvalidItemsOrKind);
            add(&mut w2, take<T>(w, ids.pop_back()));
        };
        ids.destroy_empty();
        w2
    }
}
