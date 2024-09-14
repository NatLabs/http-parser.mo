import Debug "mo:base/Debug";
import HttpParser "../src";

let headers = HttpParser.Headers([]);
var url = HttpParser.URL("https://example.com/%C3%A7a_va", headers);

// Debug.print(url.path.original);
assert url.path.original == "/ça_va";

url := HttpParser.URL("path/not/a/path", headers);
assert url.path.original == "/path/not/a/path";

url := HttpParser.URL("/symbols/c%CC%A7%CB%99%E2%88%86a%CC%8A%C2%A8%E2%88%86%C2%B4%CB%86%CB%9A%C3%9F%C2%A8c%CC%A7%C3%9F.pdf", headers);

Debug.print(url.path.original);
assert url.path.original == "/symbols/ç˙∆å¨∆´ˆ˚ß¨çß.pdf";

assert  ?"/symbols/ç˙∆å¨∆´ˆ˚ß¨çß.pdf" == HttpParser.decodeURI(HttpParser.encodeURI(url.path.original));