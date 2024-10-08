module wrapper::vesting {

    use std::ascii;
    use std::string;
    use std::type_name;
    use std::vector;
    use sui::balance;
    use sui::balance::Balance;
    use sui::bcs;
    use sui::clock;
    use sui::clock::Clock;
    use sui::coin;
    use sui::coin::Coin;
    use sui::event;
    use sui::event::emit;
    use sui::hash::blake2b256;
    use sui::math::max;
    use sui::object;
    use sui::tx_context::TxContext;
    use discover::message;
    use wrapper::wrapper::{Wrapper, new, reward};

    // === Vesting Error Codes ===
    const EWrapperVestingAllowedEmptyOrVesting: u64 = 0;
    const EVestingCycleMustBeAtLeastOneMinute: u64 = 1;
    const EVestingInitialExceedsLimit: u64 = 2;
    const EVestingStartExceedsLimit: u64 = 3;
    const EVestingCycleMustGTECliffCycle: u64 = 4;
    const EVestingWrapperNotSchedule: u64 = 5;
    const EVestingWrapperHasReleased: u64 = 6;
    const EVestingWrapperMustReleased: u64 = 7;
    const EVestingWrapperMustNotReleased: u64 = 8;
    const EVestingWrapperInvalidReleaseAmount: u64 = 9;
    const EVestingWrapperInvalidRevokeAmount: u64 = 10;
    const EVestingWrapperInvalidSeparateAmount: u64 = 11;
    const EVestingWrapperInvalidSyncClaim: u64 = 12;
    const EVestingWrapperClaimAllowedAfterScheduleStart: u64 = 13;
    const EWrapperCombineAllowedVesting: u64 = 14;
    const EVestingWrapperInvalidSchedule: u64 = 15;

    // ===== Wrapper Kind Constants =====
    const VESTING_WRAPPER_KIND: vector<u8> = b"VESTING WRAPPER";


    //2024/7/3
    const VESTING_DEPLOY_TIME_MS: u64 = 1_720_000_000_000;

    //60s
    const CYCLE_TIME_MS: u64 = 60 * 1000;

    // =============== Vesting Extension Functions ===============

    /// Struct representing the progress of vesting for a specific type.
    public struct Progress<phantom T> has store {
        id: ID,
        // Unique identifier for the vesting progress
        initial: Balance<T>,
        // Initially released balance
        vesting: Balance<T>,
        // Balance that is vested over time
        claimed: u64,
        // Number of periods that have already been claimed
    }


    /// Struct representing the schedule of vesting for a specific type.
    public struct Schedule<phantom T> has copy, drop, store {
        cliff: u64,
        // Cliff period duration
        vesting: u64,
        // Total vesting period duration
        initial: u64,
        // Initial release percentage in basis points
        cycle: u64,
        // Vesting cycle duration in minute
        start: u64,
        // Start time of the vesting schedule
    }

    /// Represents a dynamic field key for an item in a Wrapper.
    /// Each item in a Wrapper has a unique identifier of type ID.
    public struct Item has store, copy, drop { id: ID }


    /// Checks if the given wrapper is of vesting type.
    public fun is_vesting(w: &Wrapper): bool {
        w.kind() == std::ascii::string(VESTING_WRAPPER_KIND)
    }

    /// Generates a unique identifier for the given vesting schedule.
    public fun vesting_id<T>(vesting: &Schedule<T>): ID {
        let mut v_bcs = bcs::to_bytes(vesting);
        vector::append(&mut v_bcs, bcs::to_bytes(&type_name::get<T>()));
        object::id_from_bytes(blake2b256(&v_bcs))
    }

    /// Returns the start timestamp of the vesting schedule.
    public fun start_timestamp_ms<T>(vesting: &Schedule<T>): u64 {
        vesting.start
    }

    /// Returns the initial percentage of the vesting schedule.
    public fun initial<T>(vesting: &Schedule<T>): u64 {
        vesting.initial
    }

    /// Returns the cliff period of the vesting schedule.
    public fun cliff_cycle<T>(vesting: &Schedule<T>): u64 {
        vesting.cliff
    }

    /// Returns the vesting period of the vesting schedule.
    public fun vesting_cycle<T>(vesting: &Schedule<T>): u64 {
        vesting.vesting
    }

    /// Returns the cycle duration of the vesting schedule.
    public fun cycle_timestamp_ms<T>(vesting: &Schedule<T>): u64 {
        vesting.cycle * 60 * 1000
    }

    /// Initializes a vesting schedule in the given wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `start`: The start time of the vesting schedule.
    /// - `initial`: The initial percentage of the vesting schedule.
    /// - `cliff`: The cliff period of the vesting schedule.
    /// - `vesting`: The total vesting period.
    /// - `cycle`: The vesting cycle duration.
    /// Errors:
    /// - `EWrapperVestingAllowedEmptyOrVesting`: If the wrapper is not empty or of vesting type.
    /// - `EVestingCycleMustBeAtLeastOneDay`: If the cycle duration is less than one day.
    /// - `EVestingInitialExceedsLimit`: If the initial percentage exceeds the limit.
    /// - `EVestingStartExceedsLimit`: If the start time is earlier than the deployment time.
    /// - `EVestingCycleMustGTECliffCycle`: If the vesting period is less than the cliff period.
    public entry fun vesting<T>(w: &mut Wrapper, start: u64, initial: u64, cliff: u64, vesting: u64, cycle: u64) {
        assert!(is_vesting(w) || w.is_empty(), EWrapperVestingAllowedEmptyOrVesting);
        assert!(cycle >= 1, EVestingCycleMustBeAtLeastOneMinute);
        assert!(initial <= 10_000, EVestingInitialExceedsLimit);
        assert!(start >= VESTING_DEPLOY_TIME_MS, EVestingStartExceedsLimit);
        assert!(vesting >= cliff, EVestingCycleMustGTECliffCycle);

        // update vesting wrapper alias
        let mut alias = b"VESTING ";
        vector::append(&mut alias, type_name::get<T>().get_module().into_bytes());
        w.set_alias(string::utf8(alias));

        let wvid = object::id(w);
        if (w.is_empty() && is_vesting(w)) {
            assert!(w.exists_field<Item, Schedule<T>>(Item { id: wvid }), EVestingWrapperNotSchedule);
            let schedule: &mut Schedule<T> = w.mutate_field<Item, Schedule<T>>(Item { id: wvid });
            schedule.start = start;
            schedule.initial = initial;
            schedule.cliff = cliff;
            schedule.vesting = vesting;
            schedule.cycle = cycle;
        }else if (w.is_empty()) {
            w.set_kind(ascii::string(VESTING_WRAPPER_KIND));
            w.add_field(Item { id: wvid }, Schedule<T> { start, initial, cliff, vesting, cycle });
        }else {
            abort EVestingWrapperHasReleased
        }
    }

    /// Event emitted when some coin released to the Wrapper.
    public struct Released has copy, drop {
        id: ID,
        amount: u64,
    }

    /// Releases the vesting balance into the given wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `c`: Coin to be released into the vesting schedule.
    /// Errors:
    /// - `EVestingWrapperMustNotReleased`: If the wrapper has already been released.
    /// - `EVestingWrapperInvalidReleaseAmount`: If the coin value is invalid for release.
    public entry fun release<T>(w: &mut Wrapper, c: Coin<T>, ctx: &mut TxContext) {
        message::produce(reward(10), ctx.sender(), ctx);
        assert!(is_vesting(w) && w.is_empty(), EVestingWrapperMustNotReleased);
        assert!(c.value() > 0, EVestingWrapperInvalidReleaseAmount);
        let vschedule = w.borrow_field<Item, Schedule<T>>(Item { id: object::id(w) });
        let initial_balance = c.value() / 10000 * vschedule.initial;

        // update state
        let mut vesting_balance = c.into_balance<T>();
        let vprogress = Progress {
            id: vesting_id(vschedule),
            initial: balance::split<T>(&mut vesting_balance, initial_balance),
            vesting: vesting_balance,
            claimed: 0
        };
        process_release(w, vprogress);
    }

    /// Add the release process as a dynamic field in a Released Vesting Wrapper
    fun process_release<T>(w: &mut Wrapper, process: Progress<T>) {
        assert!(is_vesting(w) && w.is_empty(), EVestingWrapperMustReleased);
        event::emit(Released {
            id: process.id,
            amount: process.vesting.value() + process.initial.value(),
        });
        w.add_item(process.id.to_bytes());
        w.add_field(Item { id: process.id }, process);
    }


    /// Calculates the total amount available for vesting in the wrapper.
    public fun total_amount<T>(w: &Wrapper): u64 {
        assert!(is_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
        let vprogress = w.borrow_field<Item, Progress<T>>(Item { id: object::id_from_bytes(w.item(0)) });
        vprogress.vesting.value() + vprogress.initial.value()
    }

    /// Calculates the amount available for vesting in the wrapper.
    public fun initial_amount<T>(w: &Wrapper): u64 {
        assert!(is_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
        let vprogress = w.borrow_field<Item, Progress<T>>(Item { id: object::id_from_bytes(w.item(0)) });
        vprogress.initial.value()
    }

    /// Calculates the amount available for vesting in the wrapper.
    public fun vesting_amount<T>(w: &Wrapper): u64 {
        assert!(is_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
        let vprogress = w.borrow_field<Item, Progress<T>>(Item { id: object::id_from_bytes(w.item(0)) });
        vprogress.vesting.value()
    }

    /// Calculates the claimed vesting cycle available for vesting in the wrapper.
    public fun claimed_vesting<T>(w: &Wrapper): u64 {
        assert!(is_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
        let vprogress = w.borrow_field<Item, Progress<T>>(Item { id: object::id_from_bytes(w.item(0)) });
        vprogress.claimed
    }


    /// Retrieves the vesting schedule from the given wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - The vesting schedule.
    /// Errors:
    /// - `EVestingWrapperMustReleased`: If the wrapper has already been released.
    public fun schedule<T>(w: &Wrapper): &Schedule<T> {
        assert!(is_vesting(w), EVestingWrapperMustReleased);
        let vschedule = w.borrow_field<Item, Schedule<T>>(Item { id: object::id(w) });
        vschedule
    }

    /// Revokes the vesting schedule in the given wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// Errors:
    /// - `EVestingWrapperMustReleased`: If the wrapper has already been released.
    /// - `EVestingWrapperInvalidRevokeAmount`: If the amount in the wrapper is not zero.
    public entry fun revoke<T>(mut w: Wrapper) {
        assert!(is_vesting(&w) && !w.is_empty(), EVestingWrapperMustReleased);
        assert!(total_amount<T>(&w) == 0, EVestingWrapperInvalidRevokeAmount);

        let wid = object::id(&w);
        let vtid = object::id_from_bytes(w.item(0));

        // If the vesting is completed, set it to an empty vesting
        w.remove_item(0);
        let Progress { id: _, initial, vesting, claimed: _ } = w.remove_field<Item, Progress<T>>(
            Item { id: vtid }
        );
        balance::destroy_zero(initial);
        balance::destroy_zero(vesting);

        let Schedule { cliff: _, vesting: _, initial: _, cycle: _, start: _ } = w.remove_field<Item, Schedule<T>>(
            Item { id: wid }
        );
        w.destroy_empty();
    }

    /// Event emitted when vesting Separated.
    public struct Separated has copy, drop {
        id: ID,
        cliamed: u64,
        total_amount: u64,
        amount1: u64,
        amount2: u64,
    }

    #[allow(unused_mut)]
    /// Splits the vesting schedule into a new wrapper with the specified amount.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `amount`: Amount to be split into the new wrapper.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A new Wrapper containing the split vesting schedule.
    /// Errors:
    /// - `EVestingWrapperMustReleased`: If the wrapper has already been released.
    /// - `EVestingWrapperInvalidSeparateAmount`: If the specified amount is invalid for separation.
    public fun separate<T>(w: &mut Wrapper, amount: u64, ctx: &mut TxContext): Wrapper {
        message::produce(reward(4), ctx.sender(), ctx);
        assert!(is_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
        let total_value = total_amount<T>(w);
        assert!(amount < total_value, EVestingWrapperInvalidSeparateAmount);

        // create a new vesting
        let vschedule = w.borrow_field<Item, Schedule<T>>(Item { id: object::id(w) });
        let mut new_wrapper = new(ctx);
        vesting<T>(
            &mut new_wrapper,
            vschedule.start,
            vschedule.initial,
            vschedule.cliff,
            vschedule.vesting,
            vschedule.cycle
        );

        // get old vprogress
        let vtid = object::id_from_bytes(w.item(0));
        let mut vprogress = w.mutate_field<Item, Progress<T>>(Item { id: vtid });
        let total_amount = vprogress.initial.value() + vprogress.vesting.value();

        // create a separate balance and release
        let initial_split_amount = (vprogress.initial.value() * amount) / total_value;
        let separate_initial_balance = balance::split<T>(&mut vprogress.initial, initial_split_amount);
        let separate_vesting_balance = balance::split<T>(&mut vprogress.vesting, amount - initial_split_amount);
        event::emit(Separated {
            id: vtid,
            cliamed: vprogress.claimed,
            total_amount,
            amount1: vprogress.initial.value() + vprogress.vesting.value(),
            amount2: separate_initial_balance.value() + separate_vesting_balance.value()
        });
        // update new vesting progress state
        process_release(&mut new_wrapper, Progress<T> {
            id: vtid,
            initial: separate_initial_balance,
            vesting: separate_vesting_balance,
            claimed: vprogress.claimed
        });
        new_wrapper
    }


    /// Event emitted when vesting Claimed.
    public struct Claimed has copy, drop {
        id: ID,
        cliamed: u64,
        claim_amount: u64,
        remanent: u64,
    }

    #[allow(unused_mut)]
    /// Claims the vesting balance from the wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `clk`: Reference to the Clock.
    /// - `ctx`: Transaction context.
    /// Errors:
    /// - `EVestingWrapperMustReleased`: If the wrapper has already been released.
    /// - `EVestingWrapperClaimAllowedAfterScheduleStart`: If claiming is attempted before the vesting schedule starts.
    public entry fun claim<T>(w: &mut Wrapper, clk: &Clock, ctx: &mut TxContext) {
        message::produce(reward(4), ctx.sender(), ctx);
        assert!(is_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
        let vtid = object::id_from_bytes(w.item(0));

        let vschedule = w.borrow_field<Item, Schedule<T>>(Item { id: object::id(w) });
        let now = clock::timestamp_ms(clk);
        assert!(now >= vschedule.start, EVestingWrapperClaimAllowedAfterScheduleStart);

        // Calculate elapsed periods
        // one cycle is 60s == 6000 ms
        let elapsed_periods = (now - vschedule.start) / (vschedule.cycle * CYCLE_TIME_MS);
        let cliff = vschedule.cliff;
        let vesting = vschedule.vesting;

        let mut vprogress = w.mutate_field<Item, Progress<T>>(Item { id: vtid });
        // Create a claim balance
        let mut claim_balance = balance::zero<T>();
        let cycle_realse_balance = if ((vesting - vprogress.claimed) <= cliff) {
            vprogress.vesting.value()
        }else {
            vprogress.vesting.value() / (vesting - cliff - vprogress.claimed)
        };

        // claim initial amount
        if (vprogress.initial.value() > 0) {
            claim_balance.join(balance::withdraw_all(&mut vprogress.initial));
        };

        // If there are valid extractable periods
        if (elapsed_periods > cliff + vprogress.claimed) {
            let should_release = cycle_realse_balance * (elapsed_periods - cliff - vprogress.claimed);
            vprogress.claimed = elapsed_periods - cliff;
            if (should_release > vprogress.vesting.value()) {
                claim_balance.join(vprogress.vesting.withdraw_all());
            }else {
                claim_balance.join(vprogress.vesting.split(should_release));
            }
        };

        event::emit(Claimed {
            id: vprogress.id,
            cliamed: vprogress.claimed,
            claim_amount: claim_balance.value(),
            remanent: total_amount<T>(w),
        });

        // transfer and destroy
        if (claim_balance.value() == 0) {
            balance::destroy_zero<T>(claim_balance);
        }else {
            transfer::public_transfer(coin::from_balance(claim_balance, ctx), ctx.sender());
        };
    }

    /// Synchronizes the claimed amounts between two vesting progress objects.
    /// Parameters:
    /// - `vschedule`: Reference to the Schedule.
    /// - `v1`: Reference to the first Progress object.
    /// - `v2`: Mutable reference to the second Progress object.
    /// Errors:
    /// - `EVestingWrapperInvalidSyncClaim`: If the claimed amount of the first Progress is not greater than the second.
    fun sync_claim<T>(vschedule: &Schedule<T>, v1: &Progress<T>, v2: &mut Progress<T>) {
        assert!(v1.claimed > v2.claimed, EVestingWrapperInvalidSyncClaim);
        let claimed_gap = v1.claimed - v2.claimed;

        // Calculate the cycle release balance for v2
        let cycle_realse_balance = if ((vschedule.vesting - v2.claimed) <= vschedule.cliff) {
            v2.vesting.value()
        }else {
            v2.vesting.value() / (vschedule.vesting - vschedule.cliff - v2.claimed)
        };

        // Calculate the sync release amount
        let sync_release_amount = cycle_realse_balance * claimed_gap;
        v2.claimed = v1.claimed;
        v2.initial.join(
            if (sync_release_amount > v2.vesting.value()) {
                v2.vesting.withdraw_all()
            }else {
                v2.vesting.split(sync_release_amount)
            }
        );
    }


    /// Event emitted when vesting Combined.
    public struct Combined has copy, drop {
        schedule_id: ID,
        vesting1: ID,
        vesting2: ID,
        cliamed: u64,
        total_amount: u64,
    }

    /// Combines two vesting wrappers into one.
    /// Parameters:
    /// - `w1`: Mutable reference to the first Wrapper.
    /// - `w2`: Mutable reference to the second Wrapper.
    /// Returns:
    /// - The combined Wrapper.
    /// Errors:
    /// - `EWrapperCombineAllowedVesting`: If either wrapper is not a vesting wrapper.
    /// - `EVestingWrapperInvalidSchedule`: If the vesting schedules of the two wrappers are not the same.
    public fun combine<T>(mut w1: Wrapper, mut w2: Wrapper): Wrapper {
        assert!(is_vesting(&w1) && is_vesting(&w2), EWrapperCombineAllowedVesting);
        assert!(w1.item(0) == w2.item(0), EVestingWrapperInvalidSchedule);
        let borrow_vschedule = schedule<T>(&w1);
        let vschedule: Schedule<T> = *borrow_vschedule;

        emit(Combined {
            schedule_id: vesting_id(&vschedule),
            vesting1: object::id(&w1),
            vesting2: object::id(&w2),
            cliamed: max(claimed_vesting<T>(&w1), claimed_vesting<T>(&w2)),
            total_amount: total_amount<T>(&w1) + total_amount<T>(&w2),
        });

        // if one of the Vesting is zero, return the other Wrapper
        if (total_amount<T>(&w1) == 0) {
            revoke<T>(w1);
            w2
        } else if (total_amount<T>(&w2) == 0) {
            revoke<T>(w2);
            w1
        } else {
            // Retrieve vesting progress for both wrappers
            let vtid = object::id_from_bytes(w1.item(0));
            let mut w1_vprogress = w1.mutate_field<Item, Progress<T>>(Item { id: vtid });
            let mut w2_vprogress = w2.mutate_field<Item, Progress<T>>(Item { id: vtid });

            // Combine vesting balances based on claimed periods
            if (w1_vprogress.claimed == w2_vprogress.claimed) {
                w1_vprogress.vesting.join(w2_vprogress.vesting.withdraw_all());
                w1_vprogress.initial.join(w2_vprogress.initial.withdraw_all());
                revoke<T>(w2);
                w1
            }else {
                if (w1_vprogress.claimed > w2_vprogress.claimed) {
                    sync_claim(&vschedule, w1_vprogress, w2_vprogress);
                    w1_vprogress.vesting.join(w2_vprogress.vesting.withdraw_all());
                    w1_vprogress.initial.join(w2_vprogress.initial.withdraw_all());
                    revoke<T>(w2);
                    w1
                }else {
                    sync_claim(&vschedule, w2_vprogress, w1_vprogress);
                    w2_vprogress.vesting.join(w1_vprogress.vesting.withdraw_all());
                    w2_vprogress.initial.join(w1_vprogress.initial.withdraw_all());
                    revoke<T>(w1);
                    w2
                }
            }
        }
    }

    #[test_only]
    public fun item_for_testing(id: ID): Item {
        Item {
            id
        }
    }
}
