#[test_only]
module wrapper::inkscription_test {
    use wrapper::wrapper;
    use wrapper::test_wrapper;
    use wrapper::inkscription;

    #[test]
    public fun test_is_inkscription() {
        let mut test_init = test_wrapper::setup();
        let mut w = test_wrapper::new_wrapper(&mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER"));

        inkscription::inkscribe(&mut w, vector[
            std::string::utf8(b"Test Ink1"),
            std::string::utf8(b"Test Ink2")]);

        assert!(inkscription::is_inkscription(&w), 0);
        transfer::public_transfer(w, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_inkscribe() {
        let mut test_init = test_wrapper::setup();
        let mut w = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );

        let ink1 = std::string::utf8(b"Ink 1");
        let ink2 = std::string::utf8(b"Ink 2");
        let inks = vector[ink1, ink2];

        inkscription::inkscribe(&mut w, inks);

        assert!(wrapper::count(&w) == 2, 0);
        assert!(wrapper::item(&w, 0) == b"Ink 1", 1);
        assert!(wrapper::item(&w, 1) == b"Ink 2", 2);

        transfer::public_transfer(w, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_erase() {
        let mut test_init = test_wrapper::setup();
        let mut w = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );

        let ink1 = std::string::utf8(b"Ink 1");
        let ink2 = std::string::utf8(b"Ink 2");
        let inks = vector[ink1, ink2];

        inkscription::inkscribe(&mut w, inks);
        inkscription::erase(&mut w, 0);

        assert!(wrapper::count(&w) == 1, 0);
        assert!(wrapper::item(&w, 0) == b"Ink 2", 1);

        transfer::public_transfer(w, @0x0);
        test_init.end();
    }

    #[test]
    public fun test_shred() {
        let mut test_init = test_wrapper::setup();
        let mut w = test_wrapper::new_wrapper(
            &mut test_init,
            std::string::utf8(b"Test Wrapper"),
            std::ascii::string(b"TEST WRAPPER")
        );

        let ink1 = std::string::utf8(b"Ink 1");
        let ink2 = std::string::utf8(b"Ink 2");
        let inks = vector[ink1, ink2];

        inkscription::inkscribe(&mut w, inks);
        assert!(wrapper::count(&w) == 2, 0);
        inkscription::shred(w);
        test_init.end();
    }
}
