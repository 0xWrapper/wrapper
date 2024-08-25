module wrapper::inkscription {

    use std::ascii;
    use std::string;
    use std::vector;
    use sui::event;
    use wrapper::wrapper::Wrapper;

    // === InkSciption Error Codes ===
    const EWrapperScribAllowedEmptyOrInkSciption: u64 = 0;
    const EWrapperEraseAllowedInkSciption: u64 = 1;
    const EIndexOutOfInkSciptionItemsBounds: u64 = 2;
    const EWrapperShredAllowedInkSciption: u64 = 3;

    // ===== InkScription Kind Constants =====
    const INKSCRIPTION_WRAPPER_KIND: vector<u8> = b"INKSCRIPTION WRAPPER";

    // ===== Ink Check functions =====

    /// Checks if the Wrapper is inkscription.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the Wrapper only contains items, false otherwise.
    public fun is_inkscription(w: &Wrapper): bool {
        w.kind() == std::ascii::string(INKSCRIPTION_WRAPPER_KIND)
    }

    // ===== Ink Public Entry functions =====

    /// Event emitted when some ink is scribe to the Wrapper.
    public struct Scribed has copy, drop {
        id: ID,
        inks: u64,
    }

    /// Appends an ink to the Inscription Wrapper.
    /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `ink`: The string to be inscribed.
    /// Errors:
    /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is neither empty nor an inscription.
    public entry fun inkscribe(w: &mut Wrapper, mut inks: vector<std::string::String>) {
        assert!(is_inkscription(w) || w.is_empty(), EWrapperScribAllowedEmptyOrInkSciption);
        if (w.is_empty()) {
            w.set_kind(ascii::string(INKSCRIPTION_WRAPPER_KIND));
        };
        event::emit(Scribed {
            id: object::id(w),
            inks: inks.length(),
        });
        vector::reverse(&mut inks);
        while (inks.length() > 0) {
            w.add_item(*string::bytes(&inks.pop_back()));
        };
        inks.destroy_empty();
    }

    /// Event emitted when some ink is erased from the Wrapper.
    public struct Erased has copy, drop {
        id: ID,
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
        assert!(is_inkscription(w), EWrapperEraseAllowedInkSciption);
        assert!(w.count() > index, EIndexOutOfInkSciptionItemsBounds);
        w.remove_item(index);
        event::emit(Erased {
            id: object::id(w),
        });
    }

    /// Shred all ink inscriptions in the Wrapper, effectively clearing it.
    /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
    /// Parameters:
    /// - `w`: The Wrapper to be burned.
    /// Errors:
    /// - `EWrapperNotEmptyOrInkSciption`: If the Wrapper is neither empty nor an ink inscription.
    public entry fun shred(mut w: Wrapper) {
        assert!(is_inkscription(&w), EWrapperShredAllowedInkSciption);
        let count = w.count();
        while (w.count() > 0) {
            w.remove_item(count);
        };
        w.destroy_empty()
    }
}
