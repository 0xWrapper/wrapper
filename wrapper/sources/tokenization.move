module wrapper::tokenization {

    use std::type_name;
    use sui::balance;
    use sui::balance::Balance;
    use sui::coin;
    use sui::coin::{TreasuryCap, Coin};
    use sui::event;
    use sui::sui::SUI;
    use sui::transfer::public_transfer;
    use wrapper::wrapper::{Wrapper, new};

    // === TOKENIZED Error Codes ===
    const EWrapperCheckAccessAllowedTokenization: u64 = 0;
    const EWrapperTokenizedInvalidSuiAmount: u64 = 1;
    const EWrapperTokenizedInvalidTokenSupply: u64 = 2;
    const EWrapperDetokenizedAllowedOwner: u64 = 3;
    const EWrapperWithdrawAllowedOwner: u64 = 4;
    const EWrapperUnlockAllowedOwner: u64 = 5;
    const EWrapperMintAllowedOwner: u64 = 6;
    const EWrapperStockingAllowedTokenization: u64 = 7;
    const EWrapperBurnAllowedTokenization: u64 = 8;
    const EWrapperTotalSupplyAllowedTokenization: u64 = 9;
    const EWrapperTreasurySupplyAllowedTokenization: u64 = 10;
    const ETokenizationWrapperInvalidWithdrawAmount: u64 = 11;
    const ETokenizationWrapperLockAllowedNotTokenized: u64 = 12;
    const ETokenizationWrapperUnlockSupplyMismatch: u64 = 13;
    const ETokenizationWrapperUnlockAllowedZeroSupply: u64 = 14;
    const ETokenizationWrapperUnlockAllowedTokenized: u64 = 15;
    const ETokenizationWrapperInvalidMintAmount: u64 = 16;

    // ===== Wrapper Kind Constants =====
    const TOKENIZED_WRAPPER_KIND: vector<u8> = b"TOKENIZATION WRAPPER";

    const SUI_MIST_PER_SUI: u64 = 1_000_000_000;

    // inception wrapper object id
    const INCEPTION_WRAPPER_OBJECT_ID: address = @0x6;

    // =============== Tokenized Extension Functions ===============


    /// Represents a dynamic field key for an item in a Wrapper.
    /// Each item in a Wrapper has a unique identifier of type ID.
    public struct Item has store, copy, drop { id: ID }

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
    public fun is_tokenization(w: &Wrapper): bool {
        w.kind() == std::ascii::string(TOKENIZED_WRAPPER_KIND)
    }

    /// Asserts that the given wrapper has the specified wrapper item.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Errors:
    /// - `EWRAPPER_TOKENIZED_NOT_TOKENIZED`: If the wrapper does not contain the specified item.
    public fun has_tokenized(wt: &Wrapper, id: ID): bool {
        is_tokenization(wt) && wt.exists_object<Item, Wrapper>(Item { id }) && vector::contains<vector<u8>>(
            &wt.items(),
            &id.to_bytes()
        )
    }

    /// Asserts that the given wrapper does not have the specified wrapper item.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Errors:
    /// - `EWRAPPER_TOKENIZED_HAS_TOKENIZED`: If the wrapper contains the specified item.
    public fun not_tokenized(wt: &Wrapper, id: ID): bool {
        is_tokenization(wt) && !wt.exists_object<Item, Wrapper>(Item { id }) && vector::contains<vector<u8>>(
            &wt.items(),
            &id.to_bytes()
        )
    }

    /// Asserts that the caller has access to the wrapper.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// - `ctx`: Reference to the transaction context.
    /// Errors:
    /// - `EWRAPPER_TOKENIZED_NOT_ACCESS`: If the caller does not have access.
    public fun has_access(wt: &Wrapper, ctx: &TxContext): bool {
        assert!(is_tokenization(wt), EWrapperCheckAccessAllowedTokenization);
        let lock = wt.borrow_field<Item, Lock>(Item { id: object::id(wt) });
        lock.owner.is_some() && ctx.sender() == lock.owner.borrow()
    }

    // ===== Tokenized Public Entry functions =====

    /// Event emitted when a tokenized object is created.
    public struct WrapperTokenized<phantom T: drop> has copy, drop {
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
    public entry fun tokenized<T: drop>(
        treasury: TreasuryCap<T>,
        o: ID,
        total_supply: u64,
        mut sui: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(sui.value() >= 2 * SUI_MIST_PER_SUI, EWrapperTokenizedInvalidSuiAmount);

        // locked treasury total supply must smaller than input total_supply
        assert!(treasury.total_supply() <= total_supply, EWrapperTokenizedInvalidTokenSupply);

        // create a new tokenized object wrapper
        let mut wt = new(ctx);
        wt.set_kind(std::ascii::string(TOKENIZED_WRAPPER_KIND));
        wt.set_alias(std::string::from_ascii(type_name::get_module(&type_name::get<T>())));

        // some id
        let tid = object::id(&treasury);
        let wtid = object::id(&wt);

        // emit event
        event::emit(WrapperTokenized<T> {
            id: wtid,
            object: o,
            treasury: tid,
            supply: total_supply,
            deposit: sui.value()
        });

        // core internal
        let vault = coin::split<SUI>(&mut sui, 2 * SUI_MIST_PER_SUI, ctx);
        // TODO
        public_transfer(vault, INCEPTION_WRAPPER_OBJECT_ID);
        wt.add_field(Item { id: wtid },
            Lock {
                id: o,
                owner: option::some(ctx.sender()),
                total_supply,
                fund: sui.into_balance()
            });
        // add items ,but not dof add item,means not add to the object store
        wt.add_item(o.to_bytes());
        // dof::add(&mut wt.id, Item{ id: oid }, wrapper_tokenized);

        // add treasury,means the treasury is in the object store
        wt.add_item(tid.to_bytes());
        wt.add_object(Item { id: tid }, treasury);

        // share the tokenized wrapper with the treasury
        transfer::public_share_object(wt);
    }

    /// Event emitted when locking a tokenized object wrapper.
    public struct WrapperLocked has copy, drop {
        id: ID,
        sender: address,
        withdraw: u64,
    }

    #[lint_allow(self_transfer)]
    /// Locks the given wrapper with the specified total supply.
    /// Lock the wrapper with the total supply, and transfer the SUI fund to the sender.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `o`: The Wrapper to lock.
    /// - `ctx`: Mutable reference to the transaction context.
    public entry fun lock(wt: &mut Wrapper, o: Wrapper, ctx: &mut TxContext) {
        // check if wrapper is not locked,must be none
        assert!(not_tokenized(wt, object::id(&o)), ETokenizationWrapperLockAllowedNotTokenized);
        // fill the lock owner and total_supply
        let wtid = object::id(wt);

        let mut lock = wt.mutate_field<Item, Lock>(Item { id: wtid });
        // fill the owner
        option::fill(&mut lock.owner, ctx.sender());
        event::emit(WrapperLocked {
            id: wtid,
            sender: ctx.sender(),
            withdraw: lock.fund.value()
        });
        // withdraw SUI fund to the sender
        transfer::public_transfer(coin::from_balance<SUI>(balance::withdraw_all(&mut lock.fund), ctx), ctx.sender());
        // fill the wrapper and owner
        wt.add_object(Item { id: object::id(&o) }, o);
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
        assert!(has_access(&wt, ctx), EWrapperDetokenizedAllowedOwner);

        // transfer treasury to sender
        let treasury_id = object::id_from_bytes(wt.item(1));
        let treasury: TreasuryCap<T> = wt.remove_object<Item, TreasuryCap<T>>(Item { id: treasury_id });
        transfer::public_transfer(treasury, tx_context::sender(ctx));

        // transfer fund to sender and delete Lock
        let wtid = object::id(&wt);

        let Lock { id: _, owner: _, total_supply: _, fund } = wt.remove_field<Item, Lock>(Item { id: wtid });
        transfer::public_transfer(coin::from_balance<SUI>(fund, ctx), tx_context::sender(ctx));

        // delete the tokenized object wrapper
        wt.remove_item(0);
        wt.remove_item(0);
        wt.destroy_empty();
    }


    /// Event emitted when withdrawing funds from a tokenized object wrapper.
    public struct TokenizationWithdraw has copy, drop {
        id: ID,
        amount: u64,
        fund: u64,
    }

    /// Withdraws funds from a tokenized object wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `amount`: Amount of funds to withdraw.
    /// - `ctx`: Mutable reference to the transaction context.
    /// Errors:
    /// - `EINSUFFICIENT_BALANCE`: If the wrapper's fund balance is less than the requested withdrawal amount.
    #[lint_allow(self_transfer)]
    public entry fun withdraw(wt: &mut Wrapper, amount: u64, ctx: &mut TxContext) {
        // Ensure the caller has access to the wrapper
        assert!(has_access(wt, ctx), EWrapperWithdrawAllowedOwner);
        // Get the wrapper ID
        let wtid = object::id(wt);
        // Borrow the lock mutably from the data frame
        let mut lock = wt.mutate_field<Item, Lock>(Item { id: wtid });
        // Check if the wrapper's fund balance is sufficient for the withdrawal
        assert!(lock.fund.value() >= amount, ETokenizationWrapperInvalidWithdrawAmount);
        // Split the specified amount from the fund
        let c = coin::from_balance<SUI>(lock.fund.split<SUI>(amount), ctx);
        event::emit(TokenizationWithdraw {
            id: wtid,
            amount,
            fund: lock.fund.value()
        });
        // Transfer the withdrawn funds to the sender
        transfer::public_transfer(c, ctx.sender());
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
        assert!(has_access(&wt, ctx), EWrapperUnlockAllowedOwner);
        // burn total supply of tokenized wrapper to unlock wrapper
        let total_supply = total_supply(&wt);
        let treasury_supply = treasury_supply<T>(&wt);
        assert!(total_supply == treasury_supply, ETokenizationWrapperUnlockSupplyMismatch);
        assert!(total_supply == 0, ETokenizationWrapperUnlockAllowedZeroSupply);

        // transfer locked wrapper ownership to sender
        let object_id = object::id_from_bytes(wt.item(0));
        assert!(has_tokenized(&wt, object_id), ETokenizationWrapperUnlockAllowedTokenized);

        let object: Wrapper = wt.remove_object<Item, Wrapper>(Item { id: object_id });
        transfer::public_transfer(object, tx_context::sender(ctx));

        // detokenized the wrapper
        detokenized<T>(wt, ctx);
    }

    /// Mints new tokens for the given wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `value`: Amount of tokens to mint.
    /// - `ctx`: Mutable reference to the transaction context.
    /// Errors:
    /// - `ETOKEN_SUPPLY_MISMATCH`: If the value to mint exceeds the maximum supply.
    public entry fun mint<T: drop>(wt: &mut Wrapper, amount: u64, ctx: &mut TxContext) {
        // check has access
        assert!(has_access(wt, ctx), EWrapperMintAllowedOwner);

        // check if total supply is less than max supply
        let total_supply = total_supply(wt);
        let treasury_supply = treasury_supply<T>(wt);
        assert!(amount + treasury_supply <= total_supply, ETokenizationWrapperInvalidMintAmount);

        // mint token
        let treasury_id = object::id_from_bytes(wt.item(1));
        let mut treasury = wt.mutate_object<Item, TreasuryCap<T>>(Item { id: treasury_id });
        let token = coin::mint(treasury, amount, ctx);

        // transfer token to owner
        transfer::public_transfer(token, tx_context::sender(ctx));
    }


    /// Event emitted when stocking additional funds into a tokenized object wrapper.
    public struct TokenizationStocking has copy, drop {
        id: ID,
        value: u64,
        fund: u64,
    }


    /// Stocks additional funds into a tokenized object wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `sui`: Coin of SUI.
    /// - `ctx`: Mutable reference to the transaction context.
    public entry fun stocking(wt: &mut Wrapper, sui: Coin<SUI>) {
        assert!(is_tokenization(wt), EWrapperStockingAllowedTokenization);
        let wtid = object::id(wt);
        let mut lock = wt.mutate_field<Item, Lock>(Item { id: wtid });
        let value = sui.value();
        lock.fund.join<SUI>(sui.into_balance());
        event::emit(TokenizationStocking {
            id: wtid,
            value,
            fund: lock.fund.value()
        });
    }

    /// Burns tokens from the given wrapper.
    /// Parameters:
    /// - `wt`: Mutable reference to the Wrapper.
    /// - `c`: The Coin to burn.
    public entry fun burn<T: drop>(wt: &mut Wrapper, c: Coin<T>) {
        assert!(is_tokenization(wt), EWrapperBurnAllowedTokenization);

        // burn token
        let treasury_id = object::id_from_bytes(wt.item(1));
        let burn_value = c.value();
        let mut treasury = wt.mutate_object<Item, TreasuryCap<T>>(Item { id: treasury_id });
        coin::burn(treasury, c);

        // update total supply
        let wtid = object::id(wt);
        let mut lock = wt.mutate_field<Item, Lock>(Item { id: wtid });
        lock.total_supply = lock.total_supply - burn_value;
    }

    /// Gets the total supply of the tokenized wrapper.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// Returns:
    /// - The total supply.
    public fun total_supply(wt: &Wrapper): u64 {
        assert!(is_tokenization(wt), EWrapperTotalSupplyAllowedTokenization);

        let lock = wt.borrow_field<Item, Lock>(Item { id: object::id(wt) });
        lock.total_supply
    }

    /// Gets the current supply of the treasury.
    /// Parameters:
    /// - `wt`: Reference to the Wrapper.
    /// Returns:
    /// - The current supply.
    public fun treasury_supply<T: drop>(wt: &Wrapper): u64 {
        assert!(is_tokenization(wt), EWrapperTreasurySupplyAllowedTokenization);

        let treasury_id = object::id_from_bytes(wt.item(1));
        let treasury = wt.borrow_object<Item, TreasuryCap<T>>(Item { id: treasury_id });
        treasury.total_supply()
    }
}
