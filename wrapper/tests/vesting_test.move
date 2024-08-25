#[test_only]
module wrapper::vesting_test {
    use sui::clock;
    use sui::coin;
    use sui::sui::SUI;
    use wrapper::wrapper;
    use sui::transfer;
    use wrapper::vesting::{
        start_timestamp_ms,
        initial,
        cliff_cycle,
        vesting_cycle,
        cycle_timestamp_ms,
        vesting_amount,
        total_amount
    };
    use wrapper::vesting;
    use wrapper::test_wrapper;

    const UserA: address = @0xa;

    #[test]
    public fun test_vesting_initialization() {
        let mut test_init = test_wrapper::setup();
        let mut wrapper = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut wrapper,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );

        let schedule = vesting::schedule<SUI>(&wrapper);
        assert!(start_timestamp_ms(schedule) == start_time, 0);
        assert!(initial(schedule) == initial_percentage, 1);
        assert!(cliff_cycle(schedule) == cliff, 2);
        assert!(vesting_cycle(schedule) == vesting_period, 3);
        assert!(cycle_timestamp_ms(schedule) == cycle * 60 * 1000, 4);

        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_vesting_destroy_before_release() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        wrapper::destroy_empty(vw);
        test_init.end();
    }

    #[test]
    public fun test_vesting_release() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );

        let s = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, s, test_init.ctx());


        assert!(vesting::initial_amount<SUI>(&vw) == 1_000_000, 0); // 10% of 10_000_000
        assert!(vesting::vesting_amount<SUI>(&vw) == 9_000_000, 1);

        transfer::public_transfer(vw, @0x0);
        test_init.end();
    }

    #[test, expected_failure(abort_code = 0)]
    public fun test_vesting_destroy_after_release() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let s = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, s, test_init.ctx());

        wrapper::destroy_empty(vw);
        test_init.end();
    }


    #[test]
    public fun test_vesting_claim() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let cycle_timestamp_ms = vesting::cycle_timestamp_ms(vesting::schedule<SUI>(&vw));

        let s = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, s, test_init.ctx());

        let clk = test_init.clock(start_time + ((cliff + 1) * cycle_timestamp_ms));
        let expected_claimed = (vesting_amount<SUI>(&vw) / (vesting_period - cliff));
        vesting::claim<SUI>(&mut vw, &clk, test_init.ctx());

        // check claimed_vesting cycle
        assert!(vesting::claimed_vesting<SUI>(&vw) == 1, 0);

        // Check that the claimed amount is correct
        assert!(vesting_amount<SUI>(&vw) == 9_000_000 - expected_claimed, 2);

        transfer::public_transfer(vw, @0x0);
        clock::share_for_testing(clk);
        test_init.end();
    }

    #[test]
    public fun test_vesting_revoke() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let cycle_timestamp_ms = vesting::cycle_timestamp_ms(vesting::schedule<SUI>(&vw));

        let s = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, s, test_init.ctx());

        let clk = test_init.clock(start_time + (vesting_period * cycle_timestamp_ms));
        // Ensure the wrapper can be revoked when balance is 0
        vesting::claim<SUI>(&mut vw, &clk, test_init.ctx());

        let claimed_vesting = vesting::claimed_vesting<SUI>(&vw);
        // check claimed_vesting cycle
        assert!(claimed_vesting == vesting_period - cliff, 0);

        // Check that the claimed amount is correct
        assert!(total_amount<SUI>(&vw) == 0, 1);

        // revoke a empty vesting
        vesting::revoke<SUI>(vw);

        clock::share_for_testing(clk);
        test_init.end();
    }

    #[test]
    public fun test_vesting_separate() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let s = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, s, test_init.ctx());

        let separated_wrapper = vesting::separate<SUI>(&mut vw, 5_000_000, test_init.ctx());
        assert!(
            vesting::initial_amount<SUI>(&separated_wrapper) == 500_000,
            0
        ); // 10% of 5_000_000

        assert!(vesting::vesting_amount<SUI>(&separated_wrapper) == 4_500_000, 1);

        transfer::public_transfer(vw, @0x0);
        transfer::public_transfer(separated_wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_vesting_separate_after_cliam() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let s = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, s, test_init.ctx());


        let cycle_timestamp_ms = vesting::cycle_timestamp_ms(vesting::schedule<SUI>(&vw));
        let clk = test_init.clock(start_time + ((cliff + 1) * cycle_timestamp_ms));
        vesting::claim<SUI>(&mut vw, &clk, test_init.ctx());

        assert!(vesting::claimed_vesting<SUI>(&vw) == 1, 0);
        assert!(vesting::initial_amount<SUI>(&vw) == 0, 1);
        assert!(vesting::vesting_amount<SUI>(&vw) == 8_500_000, 2);

        let separated_wrapper = vesting::separate<SUI>(&mut vw, 5_000_000, test_init.ctx());

        assert!(vesting::claimed_vesting<SUI>(&vw) == 1, 0);
        assert!(vesting::initial_amount<SUI>(&vw) == 0, 1);
        assert!(vesting::vesting_amount<SUI>(&vw) == 3_500_000, 2);

        assert!(vesting::claimed_vesting<SUI>(&separated_wrapper) == 1, 0);
        assert!(vesting::initial_amount<SUI>(&separated_wrapper) == 0, 1);
        assert!(vesting::vesting_amount<SUI>(&separated_wrapper) == 5_000_000, 2);

        clock::share_for_testing(clk);
        transfer::public_transfer(vw, @0x0);
        transfer::public_transfer(separated_wrapper, @0x0);
        test_init.end();
    }


    #[test]
    public fun test_vesting_sync() {
        let mut test_init = test_wrapper::setup();
        test_init.next_tx_with_sender(UserA);
        {
            let mut wrapper1 = wrapper::new(test_init.ctx());
            let mut wrapper2 = wrapper::new(test_init.ctx());
            let start_time = 1_730_000_000_000;
            let initial_percentage = 1000; // 10%
            let cliff = 6; // 6 months
            let vesting_period = 24; // 2 years
            let cycle = 1 * 30 * 24 * 60; // 1 month

            vesting::vesting<SUI>(
                &mut wrapper1,
                start_time,
                initial_percentage,
                cliff,
                vesting_period,
                cycle
            );
            let coin1 = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
            vesting::release<SUI>(&mut wrapper1, coin1, test_init.ctx());

            vesting::vesting<SUI>(
                &mut wrapper2,
                start_time,
                initial_percentage,
                cliff,
                vesting_period,
                cycle
            );
            let coin2 = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
            vesting::release<SUI>(&mut wrapper2, coin2, test_init.ctx());

            // Simulate some claims on wrapper2
            let cycle_timestamp_ms = vesting::cycle_timestamp_ms(vesting::schedule<SUI>(&wrapper2));
            let clk = test_init.clock(start_time + ((cliff + 1) * cycle_timestamp_ms));
            vesting::claim<SUI>(&mut wrapper2, &clk, test_init.ctx());


            assert!(vesting::claimed_vesting<SUI>(&wrapper1) == 0, 0);
            assert!(vesting::initial_amount<SUI>(&wrapper1) == 1_000_000, 1);
            assert!(vesting::vesting_amount<SUI>(&wrapper1) == 9_000_000, 2);

            assert!(vesting::claimed_vesting<SUI>(&wrapper2) == 1, 3);
            assert!(vesting::initial_amount<SUI>(&wrapper2) == 0, 4);
            assert!(vesting::vesting_amount<SUI>(&wrapper2) == 8_500_000, 5);


            // combine wrapper1 to wrapper2
            let vw = vesting::combine<SUI>(wrapper2, wrapper1);

            assert!(vesting::claimed_vesting<SUI>(&vw) == 1, 6);
            assert!(vesting::initial_amount<SUI>(&vw) == 1_500_000, 7);
            assert!(vesting::vesting_amount<SUI>(&vw) == 17_000_000, 8);

            transfer::public_transfer(vw, @0x0);
            clock::share_for_testing(clk);
        };
        test_init.end();
    }

    #[test]
    public fun test_vesting_zero_initial_percentage() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 0; // 0%
        let cliff = 6; // 6 months
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let coin1 = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, coin1, test_init.ctx());

        assert!(vesting::claimed_vesting<SUI>(&vw) == 0, 0);
        assert!(vesting::initial_amount<SUI>(&vw) == 0, 1);
        assert!(vesting::vesting_amount<SUI>(&vw) == 10_000_000, 2);

        transfer::public_transfer(vw, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_vesting_no_cliff() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 0; // no cliff
        let vesting_period = 24; // 2 years
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let coin1 = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, coin1, test_init.ctx());

        assert!(vesting::claimed_vesting<SUI>(&vw) == 0, 0);
        assert!(vesting::initial_amount<SUI>(&vw) == 1_000_000, 1);
        assert!(vesting::vesting_amount<SUI>(&vw) == 9_000_000, 2);

        let cycle_timestamp_ms = vesting::cycle_timestamp_ms(vesting::schedule<SUI>(&vw));
        let clk = test_init.clock(start_time + ((cliff + 1) * cycle_timestamp_ms));

        // Check that the claimed amount is correct
        let expected_claimed = (vesting::vesting_amount<SUI>(&vw) / vesting_period);

        vesting::claim<SUI>(&mut vw, &clk, test_init.ctx());

        assert!(vesting::claimed_vesting<SUI>(&vw) == 1, 0);
        assert!(vesting::initial_amount<SUI>(&vw) == 0, 1);
        assert!(vesting::vesting_amount<SUI>(&vw) == 9_000_000 - expected_claimed, 2);

        clock::share_for_testing(clk);
        transfer::public_transfer(vw, @0x0);
        test_init.end();
    }

    #[test, expected_failure(abort_code = 4)]
    public fun test_vesting_no_vesting_period() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 month
        let vesting_period = 0; // no vesting
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );

        transfer::public_transfer(vw, @0x0);
        test_init.end();
    }

    #[test, expected_failure(abort_code = 1)]
    public fun test_vesting_no_cycle() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 1000; // 10%
        let cliff = 6; // 6 month
        let vesting_period = 24; // 24 month
        let cycle = 0; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );

        transfer::public_transfer(vw, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_vesting_full_initial_percentage() {
        let mut test_init = test_wrapper::setup();
        let mut vw = wrapper::new(test_init.ctx());
        let start_time = 1_730_000_000_000;
        let initial_percentage = 10000; // 100%
        let cliff = 6; // 6 month
        let vesting_period = 24; // 24 month
        let cycle = 1 * 30 * 24 * 60; // 1 month

        vesting::vesting<SUI>(
            &mut vw,
            start_time,
            initial_percentage,
            cliff,
            vesting_period,
            cycle
        );
        let coin1 = coin::mint_for_testing<SUI>(10_000_000, test_init.ctx());
        vesting::release<SUI>(&mut vw, coin1, test_init.ctx());

        assert!(vesting::claimed_vesting<SUI>(&vw) == 0, 0);
        assert!(vesting::initial_amount<SUI>(&vw) == 10_000_000, 1);
        assert!(vesting::vesting_amount<SUI>(&vw) == 0, 2);

        let clk1 = test_init.clock(start_time);
        vesting::claim<SUI>(&mut vw, &clk1, test_init.ctx());
        clock::share_for_testing(clk1);
        assert!(vesting::claimed_vesting<SUI>(&vw) == 0, 3);
        assert!(vesting::initial_amount<SUI>(&vw) == 0, 4);
        assert!(vesting::vesting_amount<SUI>(&vw) == 0, 5);

        transfer::public_transfer(vw, @0x0);
        test_init.end();
    }
}

