import Debug "mo:base/Debug";
import HttpParser "../src";

let headers = HttpParser.Headers([]);
let url = HttpParser.URL("https://example.com/%C3%A7a_va", headers);

Debug.print(url.path.original);
assert url.path.original == "/ça_va";
