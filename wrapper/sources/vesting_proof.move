// module wrapper::vesting_proof {
//
//     use std::ascii;
//     use std::ascii::string;
//     use std::string;
//     use std::type_name;
//     use sui::balance;
//     use sui::balance::Balance;
//     use sui::bcs;
//     use sui::clock;
//     use sui::clock::Clock;
//     use sui::coin;
//     use sui::coin::Coin;
//     use sui::hash::blake2b256;
//     use sui::tx_context::TxContext;
//     use sui::object::ID;
//     use sui::transfer::{public_transfer, transfer};
//     use wrapper::wrapsy::wrap;
//     use wrapper::wrapper::{Wrapper, new};
//
//     // === Vesting Error Codes ===
//     const EWrapperVestingAllowedEmptyOrVesting: u64 = 0;
//     const EVestingCycleMustBeAtLeastOneMinute: u64 = 1;
//     const EVestingInitialExceedsLimit: u64 = 2;
//     const EVestingStartExceedsLimit: u64 = 3;
//     const EVestingCycleMustGTECliffCycle: u64 = 4;
//     const EVestingWrapperNotSchedule: u64 = 5;
//     const EVestingWrapperHasReleased: u64 = 6;
//     const EVestingWrapperMustReleased: u64 = 6;
//     const EVestingWrapperRevokeAllowedProofVesting: u64 = 7;
//     const EVestingWrapperInvalidReleaseAmount: u64 = 6;
//     const EVestingWrapperInvalidReleaseProofType: u64 = 7;
//     const EVestingWrapperInvalidRevokeAmount: u64 = 8;
//     const EVestingWrapperInvalidSeparateAmount: u64 = 9;
//     const EVestingWrapperInvalidSyncClaim: u64 = 10;
//     const EVestingWrapperClaimAllowedAfterScheduleStart: u64 = 11;
//     const EWrapperCombineAllowedVesting: u64 = 12;
//     const EVestingWrapperInvalidSchedule: u64 = 13;
//
//     // ===== Wrapper Kind Constants =====
//     const PROOF_VESTING_WRAPPER_KIND: vector<u8> = b"PROOF VESTING WRAPPER";
//     const PROOF_VESTING_DEPLOY_TIME_MS: u64 = 1_720_000_000_000; // 示例时间戳
//
//     // ===============Proof Vesting Extension Functions ===============
//
//     /// Struct representing the progress of vesting for a specific type.
//     public struct Progress<phantom R> has store {
//         id: ID,
//         initial: Balance<R>,
//         vesting: Balance<R>,
//         claimed: u64,
//     }
//
//     /// Struct representing the schedule of vesting for a specific type.
//     public struct Schedule<phantom R> has copy, drop, store {
//         releaser: address,
//         // Releaser is Schedule publisher
//         proof: ascii::String,
//         // Proof is type of WorkProof
//         cliff: u64,
//         // Cliff period duration
//         vesting: u64,
//         // Total vesting period duration
//         initial: u64,
//         // Initial release percentage in basis points
//         cycle: u64,
//         // Vesting cycle duration in minute
//         start: u64,
//         // Start time of the vesting schedule
//     }
//
//     /// Struct representing the proof of work.
//     public struct Proof<P: key + store> has key, store {
//         id: ID,
//         proof: P,
//         allotment: u64
//     }
//
//     /// Generates a proof of work object.
//     public fun generate_proof<P: store + key>(proof: P, allotment: u64, ctx: &mut TxContext): Proof<P> {
//         Proof {
//             id: ctx.sender(),
//             proof,
//             allotment
//         }
//     }
//
//     /// Represents a dynamic field key for an item in a Wrapper.
//     public struct Item has store, copy, drop { id: ID }
//
//     /// Checks if the given wrapper is of vesting type.
//     public fun is_proof_vesting(w: &Wrapper): bool {
//         w.kind() == std::ascii::string(PROOF_VESTING_WRAPPER_KIND)
//     }
//
//     /// Generates a unique identifier for the given vesting schedule.
//     fun vesting_id<R>(vesting: &Schedule<R>): ID {
//         let mut v_bcs = bcs::to_bytes(vesting);
//         vector::append(&mut v_bcs, bcs::to_bytes(&type_name::get<R>()));
//         object::id_from_bytes(blake2b256(&v_bcs))
//     }
//
//     /// Initializes a vesting schedule in the given wrapper.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `start`: The start time of the vesting schedule.
//     /// - `initial`: The initial percentage of the vesting schedule.
//     /// - `cliff`: The cliff period of the vesting schedule.
//     /// - `vesting`: The total vesting period.
//     /// - `cycle`: The vesting cycle duration.
//     /// Errors:
//     /// - `EWrapperVestingAllowedEmptyOrVesting`: If the wrapper is not empty or of vesting type.
//     /// - `EVestingCycleMustBeAtLeastOneDay`: If the cycle duration is less than one day.
//     /// - `EVestingInitialExceedsLimit`: If the initial percentage exceeds the limit.
//     /// - `EVestingStartExceedsLimit`: If the start time is earlier than the deployment time.
//     /// - `EVestingCycleMustGTECliffCycle`: If the vesting period is less than the cliff period.
//     public entry fun vesting<R, P>(
//         w: &mut Wrapper,
//         start: u64,
//         initial: u64,
//         cliff: u64,
//         vesting: u64,
//         cycle: u64,
//         ctx: &mut TxContext,
//     ) {
//         assert!(is_proof_vesting(w) || w.is_empty(), EWrapperVestingAllowedEmptyOrVesting);
//         assert!(cycle >= 1, EVestingCycleMustBeAtLeastOneMinute);
//         assert!(initial <= 10_000, EVestingInitialExceedsLimit);
//         assert!(start >= PROOF_VESTING_DEPLOY_TIME_MS, EVestingStartExceedsLimit);
//         assert!(vesting >= cliff, EVestingCycleMustGTECliffCycle);
//
//         // update vesting wrapper alias
//         let alias = b"VESTING ";
//         alias.push_back(type_name::get<R>().get_module().into_bytes());
//         alias.push_back(b" WITH PROOF ");
//         alias.push_back(type_name::get<P>().get_module().into_bytes());
//         w.set_alias(string::utf8(&alias));
//
//         let wvid = object::id(w);
//         if (w.is_empty()) {
//             w.set_kind(ascii::string(PROOF_VESTING_WRAPPER_KIND));
//             // add proof to schedule
//             w.add_field(
//                 Item { id: wvid },
//                 Schedule<R> {
//                     releaser: ctx.sender(),
//                     proof: type_name::into_string(type_name::get<P>())
//                     , start, initial, cliff, vesting, cycle
//                 });
//         }else if (w.is_empty() && is_proof_vesting(w)) {
//             assert!(w.exists_field<Item, Schedule<R>>(Item { id: wvid }), EVestingWrapperNotSchedule);
//             let schedule: &mut Schedule<R> = w.mutate_field<Item, Schedule<R>>(Item { id: wvid });
//             schedule.proof = type_name::into_string(type_name::get<P>());
//             schedule.start = start;
//             schedule.initial = initial;
//             schedule.cliff = cliff;
//             schedule.vesting = vesting;
//             schedule.cycle = cycle;
//         }else {
//             abort EVestingWrapperHasReleased
//         }
//     }
//
//     /// Releases the vesting balance into the given wrapper.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `c`: Coin to be released into the vesting schedule.
//     /// Errors:
//     /// - `EVestingWrapperHasReleased`: If the wrapper has already been released.
//     /// - `EVestingWrapperInvalidReleaseAmount`: If the coin value is invalid for release.
//     public entry fun release<R, P>(w: &mut Wrapper, c: Coin<R>) {
//         assert!(is_proof_vesting(w) && w.is_empty(), EVestingWrapperMustReleased);
//         assert!(c.value() > 0, EVestingWrapperInvalidReleaseAmount);
//         let vschedule = w.borrow_field<Item, Schedule<R>>(Item { id: object::id(w) });
//         assert!(vschedule.proof == type_name::into_string(type_name::get<P>()), EVestingWrapperInvalidReleaseProofType);
//         let initial_balance = c.value() / 10000 * vschedule.initial;
//
//         // update state
//         let vid = vesting_id<R>(vschedule);
//         w.add_item(vid.to_bytes());
//         let mut vesting_balance = c.into_balance<R>();
//         let vprogress = Progress {
//             id: vid,
//             initial: balance::split<R>(&mut vesting_balance, initial_balance),
//             vesting: vesting_balance,
//             claimed: 0
//         };
//         w.add_field(Item { id: vid }, vprogress);
//     }
//
//
//     #[allow(unused_mut)]
//     /// Claims the vesting balance from the wrapper.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// - `clk`: Reference to the Clock.
//     /// - `ctx`: Transaction context.
//     /// Errors:
//     /// - `EVestingWrapperHasReleased`: If the wrapper has already been released.
//     /// - `EVestingWrapperClaimAllowedAfterScheduleStart`: If claiming is attempted before the vesting schedule starts.
//     public entry fun claim<R, P>(w: &mut Wrapper, proof: Proof<P>, clk: &Clock, ctx: &mut TxContext) {
//         assert!(is_proof_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
//         let vtid = object::id_from_bytes(w.item(0));
//
//         let vschedule = w.borrow_field<Item, Schedule<R>>(Item { id: object::id(&w) });
//         let now = clock::timestamp_ms(clk);
//         assert!(now >= vschedule.start, EVestingWrapperClaimAllowedAfterScheduleStart);
//
//         // Calculate elapsed periods
//         // one cycle is 60s == 6000 ms
//
//
// //        计算证明中的时间
//         let elapsed_periods = (now - vschedule.start) / (vschedule.cycle * 60 * 1000);
//         let cliff = vschedule.cliff;
//         let vesting = vschedule.vesting;
//
//         let mut vprogress = w.mutate_field<Item, Progress<R>>(Item { id: vtid });
//         // Create a claim balance
//         let mut claim_balance = balance::zero<R>();
//         let cycle_realse_balance = if ((vesting - vprogress.claimed) <= cliff) {
//             vprogress.vesting.value()
//         }else {
//             vprogress.vesting.value() / (vesting - cliff - vprogress.claimed)
//         };
//
//         // claim initial amount
//         if (vprogress.initial.value() > 0) {
//             claim_balance.join(balance::withdraw_all(&mut vprogress.initial));
//         };
//
//         // If there are valid extractable periods
//         if (elapsed_periods > cliff + vprogress.claimed) {
//             let should_release = cycle_realse_balance * (elapsed_periods - cliff - vprogress.claimed);
//             vprogress.claimed = elapsed_periods - cliff;
//             if (should_release > vprogress.vesting.value()) {
//                 claim_balance.join(vprogress.vesting.withdraw_all());
//             }else {
//                 claim_balance.join(vprogress.vesting.split(should_release));
//             }
//         };
//
//         // transfer and destroy
//         if (claim_balance.value() == 0) {
//             balance::destroy_zero<R>(claim_balance);
//         }else {
//             transfer::public_transfer(coin::from_balance(claim_balance, ctx), ctx.sender());
//         };
//         transfer::public_transfer(w, ctx.sender());
//     }
//
//     /// Calculates the total amount available for vesting in the wrapper.
//     /// Parameters:
//     /// - `w`: Reference to the Wrapper.
//     /// Returns:
//     /// - The total amount available for vesting.
//     /// Errors:
//     /// - `EVestingWrapperHasReleased`: If the wrapper has already been released.
//     public fun amount<R>(w: &Wrapper): u64 {
//         assert!(is_proof_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
//         let vprogress = w.borrow_field<Item, Progress<R>>(Item { id: object::id_from_bytes(w.item(0)) });
//         vprogress.vesting.value() + vprogress.initial.value()
//     }
//
//
//     public fun releaser<R>(w: &Wrapper): address {
//         assert!(is_proof_vesting(w) && !w.is_empty(), EVestingWrapperMustReleased);
//         let vschedule = w.borrow_field<Item, Schedule<R>>(Item { id: object::id(&w) });
//         vschedule.releaser
//     }
//
//
//     /// Revokes the vesting schedule in the given wrapper.
//     /// Parameters:
//     /// - `w`: Mutable reference to the Wrapper.
//     /// Errors:
//     /// - `EVestingWrapperHasReleased`: If the wrapper has already been released.
//     /// - `EVestingWrapperInvalidRevokeAmount`: If the amount in the wrapper is not zero.
//     public entry fun revoke<R>(mut w: Wrapper, ctx: &mut TxContext) {
//         assert!(is_proof_vesting(&w), EVestingWrapperRevokeAllowedProofVesting);
//         assert!(releaser<R>(&w) == ctx.sender(), EVestingWrapperRevokeAllowedProofVesting);
//
//         let vtid = object::id_from_bytes(w.item(0));
//         // If the vesting is completed, set it to an empty vesting
//         w.remove_item(0);
//         let Progress { id: _, initial, vesting, claimed: _ } = w.remove_field<Item, Progress<R>>(
//             Item { id: vtid }
//         );
//         if (amount<R>(&w) == 0) {
//             balance::destroy_zero(initial);
//             balance::destroy_zero(vesting);
//         }else {
//             transfer::public_transfer(coin::from_balance(initial, ctx), ctx.sender());
//             transfer::public_transfer(coin::from_balance(vesting, ctx), ctx.sender());
//         };
//
//         let wid = object::id(&w);
//         let Schedule { releaser: _, proof: _, cliff: _, vesting: _, initial: _, cycle: _, start: _ } = w.remove_field<Item, Schedule<R>>(
//             Item { id: wid }
//         );
//         w.destroy_empty();
//     }
// }
