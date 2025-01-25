import Debug "mo:base/Debug";
import HttpParser "../src";

import { suite; test } "mo:test";

let headers = HttpParser.Headers([]);

suite(
    "URL Test Vectors",
    func() {
        test(
            "Protocol",
            func() {
                assert HttpParser.URL("http://example.com", headers).protocol == "http";
                assert HttpParser.URL("https://example.com", headers).protocol == "https";
                assert HttpParser.URL("/example.com", headers).protocol == "https";
                assert HttpParser.URL("//example.com", headers).protocol == "https";
            },
        );

        test(
            "Port",
            func() {
                assert HttpParser.URL("http://example.com:8080", headers).port == 8080;
                assert HttpParser.URL("https://example.com:443", headers).port == 443;
                assert HttpParser.URL("http://example.com", headers).port == 80;
                assert HttpParser.URL("https://example.com", headers).port == 443;
            },
        );

        test(
            "Host",
            func() {
                let url1 = HttpParser.URL("http://sub.example.com", headers);
                assert url1.host.original == "sub.example.com";
                assert url1.host.array == ["sub", "example", "com"];

                let url2 = HttpParser.URL("http://example.co.uk", headers);
                assert url2.host.original == "example.co.uk";
                assert url2.host.array == ["example", "co", "uk"];

                let url3 = HttpParser.URL("http://localhost", headers);
                assert url3.host.original == "localhost";
                assert url3.host.array == ["localhost"];
            },
        );

        test(
            "Path",
            func() {
                assert HttpParser.URL("http://example.com/%C3%A7a_va", headers).path.original == "/ça_va";
                assert HttpParser.URL("path/not/a/path", headers).path.original == "/path/not/a/path";
                assert HttpParser.URL("/symbols/c%CC%A7%CB%99%E2%88%86a%CC%8A%C2%A8%E2%88%86%C2%B4%CB%86%CB%9A%C3%9F%C2%A8c%CC%A7%C3%9F.pdf", headers).path.original == "/symbols/ç˙∆å¨∆´ˆ˚ß¨çß.pdf";
                assert HttpParser.URL("", headers).path.original == "/";
                assert HttpParser.URL("/", headers).path.original == "/";
            },
        );

        test(
            "Query",
            func() {
                let url1 = HttpParser.URL("http://example.com?key1=value1&key2=value2", headers);

                assert url1.queryObj.original == "key1=value1&key2=value2";
                assert url1.queryObj.get("key1") == ?"value1";
                assert url1.queryObj.get("key2") == ?"value2";
                assert url1.queryObj.get("nonexistent") == null;
                assert url1.queryObj.keys == ["key1", "key2"];

                let url2 = HttpParser.URL("http://example.com?key=value%20with%20spaces", headers);
                assert url2.queryObj.get("key") == ?"value with spaces";

                let url3 = HttpParser.URL("http://example.com", headers);
                assert url3.queryObj.original == "";
                assert url3.queryObj.keys == [];
            },
        );

        test(
            "Anchor",
            func() {
                assert HttpParser.URL("http://example.com#section1", headers).anchor == "section1";
                assert HttpParser.URL("http://example.com/path#section2", headers).anchor == "section2";
                assert HttpParser.URL("http://example.com/path?query=1#section3", headers).anchor == "section3";
                assert HttpParser.URL("http://example.com", headers).anchor == "";
            },
        );

        test(
            "Complex URLs",
            func() {
                let url = HttpParser.URL("https://sub.example.co.uk:8443/path/to/resource?key1=value1&key2=value2#section", headers);
                assert url.protocol == "https";
                assert url.host.original == "sub.example.co.uk";
                assert url.host.array == ["sub", "example", "co", "uk"];
                assert url.port == 8443;
                assert url.path.original == "/path/to/resource";
                assert url.path.array == ["path", "to", "resource"];
                assert url.queryObj.original == "key1=value1&key2=value2";
                assert url.queryObj.get("key1") == ?"value1";
                assert url.anchor == "section";
            },
        );

        test(
            "URI Encoding/Decoding",
            func() {
                let path = "/symbols/ç˙∆å¨∆´ˆ˚ß¨çß.pdf";
                assert ?path == HttpParser.decodeURI(HttpParser.encodeURI(path));

                let url = HttpParser.URL("/test%20space", headers);
                assert url.path.original == "/test space";
            },
        );
    },
);

suite(
    "edge cases",
    func() {
        test(
            "Empty and Slash Edge Cases",
            func() {
                let emptyUrl = HttpParser.URL("", headers);
                assert emptyUrl.protocol == "https";
                assert emptyUrl.host.original == "";
                assert emptyUrl.host.array == [];
                assert emptyUrl.path.original == "/";
                assert emptyUrl.path.array == [];
                assert emptyUrl.queryObj.original == "";
                assert emptyUrl.queryObj.keys == [];
                assert emptyUrl.anchor == "";

                let slashUrl = HttpParser.URL("/", headers);
                assert slashUrl.host.original == "";
                assert slashUrl.path.original == "/";
                assert slashUrl.path.array == [];

                // let dotSlash = HttpParser.URL("./", headers);
                // assert dotSlash.path.original == "/./";
                // assert dotSlash.path.array == [".", ""];

                // let doubleDotSlash = HttpParser.URL("../", headers);
                // assert doubleDotSlash.path.original == "/../";
                // assert doubleDotSlash.path.array == ["..", ""];
            },
        );

        test(
            "Path Segment Edge Cases",
            func() {
                let emptySegments = HttpParser.URL("http://example.com//path///end", headers);
                assert emptySegments.path.original == "//path///end";
                assert emptySegments.path.array == ["", "path", "", "", "end"];

                let trailingSlash = HttpParser.URL("http://example.com/path/", headers);
                assert trailingSlash.path.original == "/path/";
                assert trailingSlash.path.array == ["path", ""];

                let multiTrailing = HttpParser.URL("http://example.com/path///", headers);
                assert multiTrailing.path.original == "/path///";
                assert multiTrailing.path.array == ["path", "", "", ""];

                // let dotSegments = HttpParser.URL("http://example.com/./path/../other/./end", headers);
                // assert dotSegments.path.original == "/./path/../other/./end";
                // assert dotSegments.path.array == [".", "path", "..", "other", ".", "end"];

                let encodedSlash = HttpParser.URL("http://example.com/path%2Fsubpath", headers);
                assert encodedSlash.path.original == "/path/subpath";
                assert encodedSlash.path.array == ["path", "subpath"];
            },
        );

        test(
            "Special Characters Edge Cases",
            func() {
                let specialChars = HttpParser.URL("http://example.com/ !@$%^&*()_+-=[]{}|;:'\",<.>/?", headers);
                assert specialChars.path.original == "/ !@$%^&*()_+-=[]{}|;:'\",<.>/";

                let unicodeChars = HttpParser.URL("http://example.com/🌟/✨/🎉", headers);
                assert unicodeChars.path.array == ["🌟", "✨", "🎉"];

                let mixedEncoding = HttpParser.URL("http://example.com/%F0%9F%8C%9F/%E2%9C%A8/%F0%9F%8E%89", headers);
                assert mixedEncoding.path.array == ["🌟", "✨", "🎉"];

                let nullBytes = HttpParser.URL("http://example.com/path%00other", headers);
                assert nullBytes.path.original == "/path\u{0000}other";
            },
        );

        test(
            "Query and Anchor Edge Cases",
            func() {
                let emptyQuery = HttpParser.URL("http://example.com?", headers);
                assert emptyQuery.queryObj.original == "";
                assert emptyQuery.queryObj.keys == [];

                let emptyQueryValues = HttpParser.URL("http://example.com?key1=&key2=", headers);
                assert emptyQueryValues.queryObj.get("key1") == ?"";
                assert emptyQueryValues.queryObj.get("key2") == ?"";

                let duplicateKeys = HttpParser.URL("http://example.com?key=value1&key=value2", headers);
                assert duplicateKeys.queryObj.get("key") == ?"value2";

                let emptyAnchor = HttpParser.URL("http://example.com#", headers);
                assert emptyAnchor.anchor == "";

                let complexAnchor = HttpParser.URL("http://example.com#section?query&anchor", headers);
                assert complexAnchor.anchor == "section?query&anchor";

                let encodedAnchor = HttpParser.URL("http://example.com#section%20with%20spaces", headers);
                assert encodedAnchor.anchor == "section with spaces";
            },
        );

    },
);
