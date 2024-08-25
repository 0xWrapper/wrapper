module wrapper::display {
    use sui::display;
    use sui::package;
    use wrapper::wrapper::Wrapper;

    public struct DISPLAY has drop {}

    /// init wrapper display when wrapper protocol publish on network
    fun init(witness: DISPLAY, ctx: &mut TxContext) {
        let publisher = package::claim(witness, ctx);
        let keys = vector[
            std::string::utf8(b"kind"),
            std::string::utf8(b"alias"),
            std::string::utf8(b"image_url"),
            std::string::utf8(b"project_url"),
        ];
        let values = vector[
            std::string::utf8(b"{kind}"),
            std::string::utf8(b"{alias}"),
            std::string::utf8(b"{content}"),
            std::string::utf8(b"https://wrapper.space"),
        ];
        let mut display = display::new_with_fields<Wrapper>(&publisher, keys, values, ctx);
        display::update_version<Wrapper>(&mut display);

        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
    }
}
