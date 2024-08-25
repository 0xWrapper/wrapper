#[test_only]
module wrapper::tokenization_test {
    use sui::object;
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use wrapper::wrapper::Wrapper;
    use wrapper::tokenization;
    use wrapper::test_wrapper;

    const Admin: address = @0x12;
    const UserA: address = @0xa;
    const UserB: address = @0xb;

    #[test]
    public fun test_tokenize_wrapper() {
        let mut test_init = test_wrapper::setup();
        let alias = std::string::utf8(b"Tokenized Wrapper");
        let kind = std::ascii::string(b"TOKENIZATION WRAPPER");
        let wrapper = test_wrapper::new_wrapper(&mut test_init, alias, kind);
        let token_wrapper_cap;
        test_wrapper::next_tx_with_sender(&mut test_init, UserA);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, object::id(&wrapper), 100, fund_coin, test_init.ctx());
        };

        token_wrapper_cap = test_init.take_share<Wrapper>(UserB);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);

        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_lock_tokenized_wrapper() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, UserA);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserB);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());

        assert!(!tokenization::not_tokenized(&token_wrapper_cap), 0);
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);
        test_init.end();
    }

    #[test, expected_failure(abort_code = 13)]
    public fun test_lock_other_tokenized_wrapper() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);
        let new_wrapper1 = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id1 = object::id(&new_wrapper1);

        test_wrapper::next_tx_with_sender(&mut test_init, UserA);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserB);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        tokenization::lock(&mut token_wrapper_cap, new_wrapper1, test_init.ctx());

        assert!(!tokenization::not_tokenized(&token_wrapper_cap), 0);
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);
        transfer::public_transfer(new_wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_mint_tokens() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, UserA);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let mut treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            let mc = coin::mint(&mut treasury, 10, test_init.ctx());
            coin::burn_for_testing(mc);
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserB);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        assert!(tokenization::total_supply(&token_wrapper_cap) == 100, 0);
        assert!(tokenization::treasury_supply<SUI>(&token_wrapper_cap) == 10, 0);
        test_init.next_tx();
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 1);
            tokenization::mint<SUI>(&mut token_wrapper_cap, 60, test_init.ctx());
            let addr = test_init.sender();
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(addr);
            assert!(mint_coin.value() == 60, 2);

            let total_supply = tokenization::total_supply(&token_wrapper_cap);
            let treasury_supply = tokenization::treasury_supply<SUI>(&token_wrapper_cap);
            assert!(total_supply == 30 + treasury_supply, 3);

            transfer::public_transfer(mint_coin, @0x0);
            test_wrapper::return_share<Wrapper>(token_wrapper_cap);
        };

        test_init.end();
    }

    #[test]
    public fun test_mint_two_times_tokens() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 1);
            tokenization::mint<SUI>(&mut token_wrapper_cap, 60, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 60, 2);

            let total_supply = tokenization::total_supply(&token_wrapper_cap);
            let treasury_supply = tokenization::treasury_supply<SUI>(&token_wrapper_cap);
            assert!(total_supply == 40 + treasury_supply, 3);

            transfer::public_transfer(mint_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);


        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::mint<SUI>(&mut token_wrapper_cap, 30, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 30, 2);

            let total_supply = tokenization::total_supply(&token_wrapper_cap);
            let treasury_supply = tokenization::treasury_supply<SUI>(&token_wrapper_cap);
            assert!(total_supply == 10 + treasury_supply, 3);

            transfer::public_transfer(mint_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);

        test_init.end();
    }

    #[test, expected_failure(abort_code = 6)]
    public fun test_mint_two_people_tokens() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 1);
            tokenization::mint<SUI>(&mut token_wrapper_cap, 60, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 60, 2);

            let total_supply = tokenization::total_supply(&token_wrapper_cap);
            let treasury_supply = tokenization::treasury_supply<SUI>(&token_wrapper_cap);
            assert!(total_supply == 40 + treasury_supply, 3);

            transfer::public_transfer(mint_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);


        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserB);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserB);
        {
            tokenization::mint<SUI>(&mut token_wrapper_cap, 30, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserB);
            assert!(mint_coin.value() == 30, 2);

            let total_supply = tokenization::total_supply(&token_wrapper_cap);
            let treasury_supply = tokenization::treasury_supply<SUI>(&token_wrapper_cap);
            assert!(total_supply == 10 + treasury_supply, 3);

            transfer::public_transfer(mint_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);

        test_init.end();
    }


    #[test]
    public fun test_withdraw_funds() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(10_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        // lock and get fund
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            let mut withdraw_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(withdraw_coin.value() == 8_000_000_000, 1);
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 2);

            tokenization::mint<SUI>(&mut token_wrapper_cap, 60, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 60, 3);

            let total_supply = tokenization::total_supply(&token_wrapper_cap);
            let treasury_supply = tokenization::treasury_supply<SUI>(&token_wrapper_cap);
            assert!(total_supply == 40 + treasury_supply, 4);

            transfer::public_transfer(withdraw_coin, @0x0);
            transfer::public_transfer(mint_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);

        // withdraw 1
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            let stocking_coin = coin::mint_for_testing<SUI>(10_000_000_000, test_init.ctx());
            tokenization::stocking(&mut token_wrapper_cap, stocking_coin);
            tokenization::withdraw(&mut token_wrapper_cap, 8_000_000_000, test_init.ctx());
            let mut withdraw_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(withdraw_coin.value() == 8_000_000_000, 2);

            transfer::public_transfer(withdraw_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);

        // withdraw 2
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::withdraw(&mut token_wrapper_cap, 2_000_000_000, test_init.ctx());
            let mut withdraw_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(withdraw_coin.value() == 2_000_000_000, 2);

            transfer::public_transfer(withdraw_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);

        test_init.end();
    }

    #[test]
    public fun test_lock_withdraw_funds() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(10_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            let mut withdraw_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(withdraw_coin.value() == 8_000_000_000, 1);
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 2);

            tokenization::mint<SUI>(&mut token_wrapper_cap, 60, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 60, 3);

            let total_supply = tokenization::total_supply(&token_wrapper_cap);
            let treasury_supply = tokenization::treasury_supply<SUI>(&token_wrapper_cap);
            assert!(total_supply == 40 + treasury_supply, 4);

            transfer::public_transfer(withdraw_coin, @0x0);
            transfer::public_transfer(mint_coin, @0x0);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);
        test_init.end();
    }


    #[test, expected_failure(abort_code = 3)]
    public fun test_detoken_tokenized_wrapper_no_access() {
        let mut test_init = test_wrapper::setup();
        let wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Tokenized Wrapper"),
            std::ascii::string(b"TOKENIZATION WRAPPER")
        );

        test_init.next_tx_with_sender(UserA);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, object::id(&wrapper), 100, fund_coin, test_init.ctx());
        };

        let token_wrapper_cap = test_init.take_share<Wrapper>(UserB);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserB);
        {
            tokenization::detokenized<SUI>(token_wrapper_cap, test_init.ctx());
        };

        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }


    #[test]
    public fun test_detoken_tokenized_wrapper() {
        let mut test_init = test_wrapper::setup();
        let wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Tokenized Wrapper"),
            std::ascii::string(b"TOKENIZATION WRAPPER")
        );

        test_init.next_tx_with_sender(UserA);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(2_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, object::id(&wrapper), 100, fund_coin, test_init.ctx());
        };

        let token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::detokenized<SUI>(token_wrapper_cap, test_init.ctx());
        };

        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }


    #[test, expected_failure(abort_code = 14)]
    public fun test_unlock_tokenized_not_mint_wrapper() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(10_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        // lock and get fund
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 2);

            tokenization::unlock<SUI>(token_wrapper_cap, test_init.ctx());
        };
        test_init.end();
    }


    #[test, expected_failure(abort_code = 14)]
    public fun test_unlock_tokenized_wrapper_not_burn_total() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(10_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        // lock and get fund
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 2);

            tokenization::mint<SUI>(&mut token_wrapper_cap, 60, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 60, 3);

            tokenization::burn<SUI>(&mut token_wrapper_cap, mint_coin);

            tokenization::unlock<SUI>(token_wrapper_cap, test_init.ctx());
        };
        test_init.end();
    }

    #[test]
    public fun test_unlock_tokenized_wrapper() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(10_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        // lock and get fund
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 2);

            tokenization::mint<SUI>(&mut token_wrapper_cap, 100, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 100, 3);

            tokenization::burn<SUI>(&mut token_wrapper_cap, mint_coin);

            tokenization::unlock<SUI>(token_wrapper_cap, test_init.ctx());
        };
        test_init.end();
    }

    #[test, expected_failure(abort_code = 5)]
    public fun test_unlock_tokenized_wrapper_two_people() {
        let mut test_init = test_wrapper::setup();
        let new_wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        let wrapper_id = object::id(&new_wrapper);

        test_wrapper::next_tx_with_sender(&mut test_init, Admin);
        {
            let mut fund_coin = coin::mint_for_testing<SUI>(10_000_000_000, test_init.ctx());
            let treasury = coin::create_treasury_cap_for_testing<SUI>(test_init.ctx());
            tokenization::tokenized(treasury, wrapper_id, 100, fund_coin, test_init.ctx());
        };

        // lock and get fund
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserA);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserA);
        {
            tokenization::lock(&mut token_wrapper_cap, new_wrapper, test_init.ctx());
            assert!(!tokenization::not_tokenized(&token_wrapper_cap), 2);

            tokenization::mint<SUI>(&mut token_wrapper_cap, 100, test_init.ctx());
            let mut mint_coin = test_init.take_from_sender<Coin<SUI>>(UserA);
            assert!(mint_coin.value() == 100, 3);
            tokenization::burn<SUI>(&mut token_wrapper_cap, mint_coin);
        };
        test_wrapper::return_share<Wrapper>(token_wrapper_cap);


        // other poeple unlock
        let mut token_wrapper_cap = test_init.take_share<Wrapper>(UserB);
        assert!(tokenization::is_tokenization(&token_wrapper_cap), 0);
        test_init.next_tx_with_sender(UserB);
        {
            tokenization::unlock<SUI>(token_wrapper_cap, test_init.ctx());
        };
        test_init.end();
    }
}
