#[test_only]
module wrapper::test_wrapper {
    use std::ascii;
    use std::string;
    use sui::clock;
    use sui::clock::Clock;
    use sui::coin;
    use sui::coin::TreasuryCap;
    use wrapper::wrapper::{Self, Wrapper, WRAPPER, is_inception};
    use sui::test_scenario::{Self, Scenario};
    use sui::test_utils;

    const ADMIN: address = @0x12;

    public struct TestInit {
        scenario: Scenario,
        inception: wrapper::Wrapper,
        coin_cap: TreasuryCap<WRAPPER>,
    }

    public fun setup(): TestInit {
        let mut scenario = test_scenario::begin(ADMIN);
        wrapper::init_for_testing(scenario.ctx());
        scenario.next_tx(ADMIN);
        let inception = test_scenario::take_from_sender<Wrapper>(&mut scenario);
        let coin_cap = test_scenario::take_from_sender<TreasuryCap<WRAPPER>>(&mut scenario);
        assert!(is_inception(&inception), 0);
        assert!(coin::total_supply(&coin_cap) == 0, 0);
        TestInit {
            scenario,
            inception,
            coin_cap,
        }
    }

    public fun new_wrapper(self: &mut TestInit, alias: string::String, kind: ascii::String): wrapper::Wrapper {
        let mut wrapper = wrapper::new(self.scenario.ctx());
        wrapper::set_alias(&mut wrapper, alias);
        wrapper::set_kind(&mut wrapper, kind);
        wrapper
    }

    public fun empty_wrapper(self: &mut TestInit, alias: string::String): wrapper::Wrapper {
        let mut wrapper = wrapper::new(self.scenario.ctx());
        wrapper::set_alias(&mut wrapper, alias);
        wrapper
    }

    public fun get_mut_inception(self: &mut TestInit): &mut Wrapper {
        &mut self.inception
    }

    public fun get_inception(self: & TestInit): & Wrapper {
        &self.inception
    }

    public fun get_mut_cap(self: &mut TestInit): &mut TreasuryCap<WRAPPER> {
        &mut self.coin_cap
    }

    public fun get_cap(self: & TestInit): & TreasuryCap<WRAPPER> {
        &self.coin_cap
    }

    public fun next_tx(self: &mut TestInit): &mut TestInit {
        self.scenario.next_tx(ADMIN);
        self
    }

    public fun ctx(self: &mut TestInit): &mut TxContext {
        self.scenario.ctx()
    }

    public fun clock(self: &mut TestInit, timestamp_ms: u64): Clock {
        let mut clk = clock::create_for_testing(self.ctx());
        // Move the clock forward to just after the cliff period
        clock::set_for_testing(
            &mut clk,
            timestamp_ms
        );
        clk
    }

    public fun sender(self: &mut TestInit): address {
        self.scenario.sender()
    }

    public fun take_from_sender<T: key>(self: &mut TestInit, sender: address): T {
        self.scenario.next_tx(sender);
        test_scenario::take_from_sender<T>(&mut self.scenario)
    }

    public fun return_to_sender<T: key>(self: &mut TestInit, t: T) {
        self.scenario.return_to_sender(t)
    }

    public fun send_to_sender<T: key+store>(self: &mut TestInit, t: T) {
        transfer::public_transfer(t, self.scenario.sender());
    }

    public fun next_tx_with_sender(self: &mut TestInit, sender: address): &mut TestInit {
        self.scenario.next_tx(sender);
        self
    }

    public fun end(self: TestInit) {
        test_utils::destroy(self);
    }

    public fun take_share<T: key>(self: &mut TestInit, sender: address): T {
        self.scenario.next_tx(sender);
        return self.scenario.take_shared<T>()
    }

    public fun return_share<T: key>(t: T) {
        test_scenario::return_shared<T>(t)
    }
}
