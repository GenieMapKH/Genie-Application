final _emailAddress = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.\w{2,}$');

/// Whether [value] (already trimmed) looks like an email address. The
/// server checks it again; this only spares a round trip for a typo.
bool isValidEmail(String value) =>
    value.length <= 254 && _emailAddress.hasMatch(value);
