#[test_only]
module wrapper::wrapper_tests {
    use std::type_name;
    use std::vector;
    use sui::coin;
    use sui::object;
    use wrapper::wrapper::{WRAPPER, Wrapper};
    use wrapper::wrapper;
    use wrapper::wrapsy;
    use wrapper::test_wrapper;

    const EItemNotFound: u64 = 0;
    const EIndexOutOfBounds: u64 = 1;
    const EItemNotSameKind: u64 = 2;
    const EWrapperNotEmpty: u64 = 3;


    public struct TestObject1 has store, key {
        id: UID,
        data: u64
    }

    public struct TestObject2 has store, key {
        id: UID,
        data: vector<u8>
    }


    #[test]
    public fun test_is_same_kind() {
        let mut test_init = test_wrapper::setup();
        let mut wrapper = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );
        let test_obj = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id = object::id(&test_obj);
        wrapsy::add(&mut wrapper, test_obj);

        assert!(wrapsy::is_same_kind<TestObject1>(&wrapper), 1);
        assert!(wrapsy::has_item_with_type<TestObject1>(&wrapper, obj_id), 2);


        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_has_item_with_type() {
        let mut test_init = test_wrapper::setup();
        let mut wrapper = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );
        let test_obj = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id = object::id(&test_obj);
        wrapsy::add(&mut wrapper, test_obj);
        assert!(wrapsy::has_item_with_type<TestObject1>(&wrapper, obj_id), 2);


        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_borrow() {
        let mut test_init = test_wrapper::setup();
        let mut wrapper = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );
        let test_obj = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id = object::id(&test_obj);
        wrapsy::add(&mut wrapper, test_obj);
        let borrowed_item: &TestObject1 = wrapsy::borrow(&wrapper, 0);
        assert!(object::id(borrowed_item) == obj_id, 2);

        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_borrow_mut() {
        let mut test_init = test_wrapper::setup();
        let mut wrapper = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );
        let test_obj = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id = object::id(&test_obj);
        wrapsy::add(&mut wrapper, test_obj);
        let borrowed_item: &mut TestObject1 = wrapsy::borrow_mut(&mut wrapper, 0);
        borrowed_item.data = 1000;
        assert!(wrapsy::has_item_with_type<TestObject1>(&wrapper, obj_id), 1);

        let borrowed_item: &TestObject1 = wrapsy::borrow(&wrapper, 0);
        assert!(object::id(borrowed_item) == obj_id, 2);
        assert!(borrowed_item.data == 1000, 3);

        transfer::public_transfer(wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_wrap() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );


        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];

        wrapsy::wrap(&mut wrap, objs,test_init.ctx());
        assert!(wrapper::count(&wrap) == 2, 0);
        let items = wrapper::items(&wrap);
        let (has1, obj1_index) = vector::index_of(&items, &object::id_to_bytes(&obj_id1));
        assert!(has1, 1);
        let (has2, obj2_index) = vector::index_of(&items, &object::id_to_bytes(&obj_id2));
        assert!(has2, 2);

        let borrowed_item1: &TestObject1 = wrapsy::borrow(&wrap, obj1_index);
        assert!(object::id(borrowed_item1) == obj_id1, 3);

        let borrowed_item2: &TestObject1 = wrapsy::borrow(&wrap, obj2_index);
        assert!(object::id(borrowed_item2) == obj_id2, 4);

        transfer::public_transfer(wrap, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_unwrap() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );


        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];
        wrapsy::wrap(&mut wrap, objs,test_init.ctx());
        assert!(wrapper::count(&wrap) == 2, 0);
        let mut wrap_coin = coin::mint_for_testing<WRAPPER>(10_000_000, test_init.ctx());
        wrapsy::unwrap<TestObject1>(wrap, wrap_coin, test_init.ctx());
        test_init.end();
    }

    #[test, expected_failure(abort_code = 4)]
    //EWrapperUnwrapInvalidSuiAmount
    public fun test_unwrap_not_enough() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );


        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];
        wrapsy::wrap(&mut wrap, objs,test_init.ctx());
        assert!(wrapper::count(&wrap) == 2, 0);


        let mut wrap_coin = coin::mint_for_testing<WRAPPER>(9_000_000, test_init.ctx());
        wrapsy::unwrap<TestObject1>(wrap, wrap_coin, test_init.ctx());


        test_init.end();
    }

    #[test]
    public fun test_add() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap, test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap, test_obj2);
        assert!(wrapper::count(&wrap) == 2, 0);
        let items = wrapper::items(&wrap);
        let (has1, obj1_index) = vector::index_of(&items, &object::id_to_bytes(&obj_id1));
        assert!(has1, 1);
        let (has2, obj2_index) = vector::index_of(&items, &object::id_to_bytes(&obj_id2));
        assert!(has2, 2);

        let borrowed_item1: &TestObject1 = wrapsy::borrow(&wrap, obj1_index);
        assert!(object::id(borrowed_item1) == obj_id1, 3);

        let borrowed_item2: &TestObject1 = wrapsy::borrow(&wrap, obj2_index);
        assert!(object::id(borrowed_item2) == obj_id2, 4);

        transfer::public_transfer(wrap, @0x0);

        test_init.end();
    }

    #[test, expected_failure(abort_code = 6)]
    public fun test_add_not_same_kind() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap, test_obj1);

        let test_obj2 = TestObject2 {
            id: object::new(test_init.ctx()),
            data: b"test",
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap, test_obj2);

        transfer::public_transfer(wrap, @0x0);

        test_init.end();
    }

    #[test]
    public fun test_shift() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper1")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper2")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap1, test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 1,
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap2, test_obj2);

        assert!(wrapper::kind(&wrap1) == wrapper::kind(&wrap2), 0);
        assert!(wrapper::kind(&wrap1) == type_name::into_string(type_name::get<TestObject1>()), 1);
        assert!(wrapper::kind(&wrap2) == type_name::into_string(type_name::get<TestObject1>()), 2);
        wrapsy::shift<TestObject1>(&mut wrap1, &mut wrap2);

        assert!(wrapper::count(&wrap1) == 0, 3);
        assert!(wrapper::count(&wrap2) == 2, 4);

        transfer::public_transfer(wrap1, @0x0);
        transfer::public_transfer(wrap2, @0x0);

        test_init.end();
    }

    #[test]
    public fun test_shift_to_empty() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper1")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper2")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap1, test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 1,
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap1, test_obj2);

        assert!(wrapper::count(&wrap1) == 2, 3);
        assert!(wrapper::count(&wrap2) == 0, 4);

        assert!(wrapper::kind(&wrap1) != wrapper::kind(&wrap2), 0);
        assert!(wrapper::kind(&wrap1) == type_name::into_string(type_name::get<TestObject1>()), 1);
        assert!(wrapper::is_empty(&wrap2), 2);
        wrapsy::shift<TestObject1>(&mut wrap1, &mut wrap2);

        assert!(wrapper::count(&wrap1) == 0, 5);
        assert!(wrapper::count(&wrap2) == 2, 6);

        transfer::public_transfer(wrap1, @0x0);
        transfer::public_transfer(wrap2, @0x0);

        test_init.end();
    }

    #[test, expected_failure(abort_code = 7)]
    public fun test_shift_empty_to() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper1")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper2")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap2, test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 1,
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap2, test_obj2);

        assert!(wrapper::count(&wrap1) == 0, 3);
        assert!(wrapper::count(&wrap2) == 2, 4);

        assert!(wrapper::kind(&wrap1) != wrapper::kind(&wrap2), 0);
        assert!(wrapper::kind(&wrap2) == type_name::into_string(type_name::get<TestObject1>()), 1);
        assert!(wrapper::is_empty(&wrap1), 2);
        wrapsy::shift<TestObject1>(&mut wrap1, &mut wrap2);

        assert!(wrapper::count(&wrap1) == 0, 5);
        assert!(wrapper::count(&wrap2) == 2, 6);

        transfer::public_transfer(wrap1, @0x0);
        transfer::public_transfer(wrap2, @0x0);

        test_init.end();
    }

    #[test, expected_failure(abort_code = 6)]
    public fun test_shift_not_same_kind() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper1")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper2")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap1, test_obj1);

        let test_obj2 = TestObject2 {
            id: object::new(test_init.ctx()),
            data: b"test",
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap2, test_obj2);

        assert!(wrapper::kind(&wrap1) != wrapper::kind(&wrap2), 0);
        assert!(wrapper::kind(&wrap1) == type_name::into_string(type_name::get<TestObject1>()), 1);
        assert!(wrapper::kind(&wrap2) == type_name::into_string(type_name::get<TestObject2>()), 2);
        wrapsy::shift<TestObject1>(&mut wrap1, &mut wrap2);


        transfer::public_transfer(wrap1, @0x0);
        transfer::public_transfer(wrap2, @0x0);

        test_init.end();
    }

    #[test]
    public fun test_remove() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );


        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];

        wrapsy::wrap(&mut wrap, objs,test_init.ctx());
        assert!(wrapper::count(&wrap) == 2, 0);
        let items = wrapper::items(&wrap);
        let (has1, obj1_index) = vector::index_of(&items, &object::id_to_bytes(&obj_id1));
        assert!(has1, 1);
        let (has2, obj2_index) = vector::index_of(&items, &object::id_to_bytes(&obj_id2));
        assert!(has2, 2);

        let removed_item1: TestObject1 = wrapsy::remove<TestObject1>(&mut wrap, obj1_index);
        assert!(object::id(&removed_item1) == obj_id1, 3);

        let removed_item2: TestObject1 = wrapsy::remove<TestObject1>(&mut wrap, obj2_index);
        assert!(object::id(&removed_item2) == obj_id2, 4);

        assert!(wrapper::count(&wrap) == 0, 5);

        transfer::public_transfer(removed_item1, @0x0);
        transfer::public_transfer(removed_item2, @0x0);
        wrapper::destroy_empty(wrap);
        test_init.end();
    }

    #[test]
    public fun test_take() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];

        wrapsy::wrap(&mut wrap, objs,test_init.ctx());
        assert!(wrapper::count(&wrap) == 2, 0);

        let removed_item1: TestObject1 = wrapsy::take<TestObject1>(&mut wrap, obj_id1);
        assert!(object::id(&removed_item1) == obj_id1, 1);

        let removed_item2: TestObject1 = wrapsy::take<TestObject1>(&mut wrap, obj_id2);
        assert!(object::id(&removed_item2) == obj_id2, 2);

        assert!(wrapper::count(&wrap) == 0, 3);

        transfer::public_transfer(removed_item1, @0x0);
        transfer::public_transfer(removed_item2, @0x0);
        wrapper::destroy_empty(wrap);
        test_init.end();
    }

    #[test]
    public fun test_merge_to_empty() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];

        wrapsy::wrap(&mut wrap1, objs,test_init.ctx());
        let wrap1_objid = object::id(&wrap1);
        assert!(wrapper::count(&wrap1) == 2, 0);
        assert!(wrapper::count(&wrap2) == 0, 1);
        assert!(wrapper::is_empty(&wrap2), 2);

        let merged_wrapper = wrapsy::merge<TestObject1>(wrap1, wrap2, test_init.ctx());
        assert!(wrapper::count(&merged_wrapper) == 2, 3);
        assert!(object::id(&merged_wrapper) == wrap1_objid, 4);

        transfer::public_transfer(merged_wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_merge_not_same() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper1")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper2")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap1, test_obj1);

        let test_obj2 = TestObject2 {
            id: object::new(test_init.ctx()),
            data: b"test",
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap2, test_obj2);

        assert!(wrapper::kind(&wrap1) != wrapper::kind(&wrap2), 0);
        assert!(wrapper::kind(&wrap1) == type_name::into_string(type_name::get<TestObject1>()), 1);
        assert!(wrapper::kind(&wrap2) == type_name::into_string(type_name::get<TestObject2>()), 2);
        let merged_wrapper = wrapsy::merge<Wrapper>(wrap1, wrap2, test_init.ctx());
        assert!(wrapper::count(&merged_wrapper) == 2, 3);
        assert!(wrapper::kind(&merged_wrapper) == type_name::into_string(type_name::get<Wrapper>()), 4);

        transfer::public_transfer(merged_wrapper, @0x0);

        test_init.end();
    }


    #[test]
    public fun test_merge_two_same() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper1")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper2")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap1, test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 1,
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap2, test_obj2);

        assert!(wrapper::kind(&wrap1) == wrapper::kind(&wrap2), 0);
        assert!(wrapper::kind(&wrap1) == type_name::into_string(type_name::get<TestObject1>()), 1);
        assert!(wrapper::kind(&wrap2) == type_name::into_string(type_name::get<TestObject1>()), 2);
        let merged_wrapper = wrapsy::merge<TestObject1>(wrap1, wrap2, test_init.ctx());
        assert!(wrapper::count(&merged_wrapper) == 2, 3);
        assert!(wrapper::kind(&merged_wrapper) == type_name::into_string(type_name::get<TestObject1>()), 4);

        transfer::public_transfer(merged_wrapper, @0x0);

        test_init.end();
    }

    #[test]
    public fun test_merge_two_same_wrapper_but_to_wrapper() {
        let mut test_init = test_wrapper::setup();
        let mut wrap1 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper1")
        );

        let mut wrap2 = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper2")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);
        wrapsy::add(&mut wrap1, test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 1,
        };
        let obj_id2 = object::id(&test_obj2);
        wrapsy::add(&mut wrap2, test_obj2);

        assert!(wrapper::kind(&wrap1) == wrapper::kind(&wrap2), 0);
        assert!(wrapper::kind(&wrap1) == type_name::into_string(type_name::get<TestObject1>()), 1);
        assert!(wrapper::kind(&wrap2) == type_name::into_string(type_name::get<TestObject1>()), 2);
        let merged_wrapper = wrapsy::merge<Wrapper>(wrap1, wrap2, test_init.ctx());
        assert!(wrapper::count(&merged_wrapper) == 2, 3);
        assert!(wrapper::kind(&merged_wrapper) == type_name::into_string(type_name::get<Wrapper>()), 4);

        transfer::public_transfer(merged_wrapper, @0x0);

        test_init.end();
    }


    #[test]
    public fun test_split() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];

        wrapsy::wrap(&mut wrap, objs,test_init.ctx());

        let new_wrapper = wrapsy::split<TestObject1>(&mut wrap, vector[ obj_id1], test_init.ctx());

        assert!(wrapper::count(&wrap) == 1, 0);
        assert!(wrapper::count(&new_wrapper) == 1, 1);
        assert!(wrapsy::has_item_with_type<TestObject1>(&wrap, obj_id2), 2);
        assert!(wrapsy::has_item_with_type<TestObject1>(&new_wrapper, obj_id1), 3);

        transfer::public_transfer(wrap, @0x0);
        transfer::public_transfer(new_wrapper, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_split_all() {
        let mut test_init = test_wrapper::setup();
        let mut wrap = test_wrapper::empty_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper")
        );

        let test_obj1 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id1 = object::id(&test_obj1);

        let test_obj2 = TestObject1 {
            id: object::new(test_init.ctx()),
            data: 0,
        };
        let obj_id2 = object::id(&test_obj2);
        let objs = vector[ test_obj1, test_obj2];

        wrapsy::wrap(&mut wrap, objs,test_init.ctx());

        let new_wrapper = wrapsy::split<TestObject1>(&mut wrap, vector[ obj_id1, obj_id2], test_init.ctx());

        assert!(wrapper::count(&wrap) == 0, 0);
        assert!(wrapper::count(&new_wrapper) == 2, 1);
        assert!(wrapsy::has_item_with_type<TestObject1>(&new_wrapper, obj_id2), 2);
        assert!(wrapsy::has_item_with_type<TestObject1>(&new_wrapper, obj_id1), 3);

        wrapper::destroy_empty(wrap);
        transfer::public_transfer(new_wrapper, @0x0);
        test_init.end();
    }
}
