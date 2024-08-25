#[test_only]
module wrapper::wrapper_test {
    use std::string;
    use std::string::{String, utf8};
    use sui::object;
    use wrapper::wrapper;
    use sui::transfer;
    use wrapper::test_wrapper;

    const ADMIN: address = @0x12;

    #[test]
    public fun test_init_wrapper() {
        let test_init = test_wrapper::setup();
        test_init.end();
    }


    #[test]
    public fun test_create_wrapper() {
        let mut test_init = test_wrapper::setup();
        let alias = std::string::utf8(b"Test Wrapper");
        let kind = std::ascii::string(b"TEST WRAPPER");
        let wrapper = test_wrapper::new_wrapper(&mut test_init, alias, kind);

        assert!(wrapper::alias(&wrapper) == alias, 0);
        assert!(wrapper::kind(&wrapper) == kind, 1);
        assert!(wrapper::count(&wrapper) == 0, 2);
        transfer::public_transfer(wrapper, ADMIN);
        test_init.end();
    }


    #[test]
    public fun test_add_items_to_wrapper() {
        let mut test_init = test_wrapper::setup();
        let mut wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );

        let item1 = b"Item 1";
        let item2 = b"Item 2";

        wrapper::add_item(&mut wrapper, item1);
        wrapper::add_item(&mut wrapper, item2);

        assert!(wrapper::count(&wrapper) == 2, 0);
        assert!(wrapper::item(&wrapper, 0) == item1, 1);
        assert!(wrapper::item(&wrapper, 1) == item2, 2);

        transfer::public_transfer(wrapper, ADMIN);
        test_init.end();
    }


    #[test]
    public fun test_destroy_empty_wrapper() {
        let mut test_init = test_wrapper::setup();
        let wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );
        wrapper::destroy_empty(wrapper);
        test_init.end();
    }

    #[test]
    public fun test_set_fields() {
        let mut test_init = test_wrapper::setup();
        let mut wrapper = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );

        let new_alias = std::string::utf8(b"New Alias");
        let new_kind = std::ascii::string(b"NEW KIND");
        wrapper::set_alias(&mut wrapper, new_alias);
        wrapper::set_kind(&mut wrapper, new_kind);

        assert!(wrapper::alias(&wrapper) == new_alias, 0);
        assert!(wrapper::kind(&wrapper) == new_kind, 1);

        wrapper::destroy_empty(wrapper);
        test_init.end();
    }

    #[test]
    public fun test_dynamic_fields() {
        let mut test_init = test_wrapper::setup();
        let mut w = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );

        // 添加动态字段
        let field_key = std::string::utf8(b"Dynamic Field");
        let field_value = std::string::utf8(b"Field Value ");
        wrapper::add_field(&mut w, field_key, field_value);

        assert!(wrapper::exists_field<String, String>(&w, field_key), 0);
        assert!(wrapper::borrow_field<String, String>(&w, field_key) == &field_value, 1);

        let new_field_value = std::string::utf8(b"New Field Value");
        let mut value = wrapper::mutate_field<String, String>(&mut w, field_key);
        string::append(value, new_field_value);

        assert!(
            wrapper::borrow_field<String, String>(&w, field_key) == &std::string::utf8(b"Field Value New Field Value"),
            2
        );

        wrapper::remove_field<String, String>(&mut w, field_key);

        assert!(!wrapper::exists_field<String, String>(&w, field_key), 3);

        wrapper::destroy_empty(w);
        test_init.end();
    }

    public struct TestObject has key, store {
        id: UID,
        value: String,
    }

    public fun value(obj: &TestObject): String {
        obj.value
    }

    #[test]
    public fun test_object_operations() {
        let mut test_init = test_wrapper::setup();
        let mut w = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );

        let object_key = std::string::utf8(b"Object Key ");

        let object_value = TestObject {
            id: object::new(test_init.ctx()),
            value: object_key,
        };
        wrapper::add_object(&mut w, object_key, object_value);

        assert!(wrapper::exists_object<String, TestObject>(&w, object_key), 0);
        let object_value = wrapper::borrow_object<String, TestObject>(&w, object_key);
        assert!(value(object_value) == object_key, 1);

        let new_object_value = b"New Object Value";
        let mut value = wrapper::mutate_object<String, TestObject>(&mut w, object_key);
        string::append(&mut value.value, utf8(new_object_value));

        assert!(
            wrapper::borrow_object<String, TestObject>(&w, object_key).value ==
                std::string::utf8(b"Object Key New Object Value"),
            2
        );

        let removed_object_value = wrapper::remove_object<String, TestObject>(&mut w, object_key);

        assert!(removed_object_value.value == std::string::utf8(b"Object Key New Object Value"), 3);
        assert!(!wrapper::exists_object<String, TestObject>(&w, object_key), 4);

        wrapper::destroy_empty(w);
        transfer::public_transfer(removed_object_value, ADMIN);
        test_init.end();
    }
}

