import Debug "mo:base/Debug";
import HttpParser "../src";

import { suite; test } "mo:test";

let { Headers } = HttpParser;

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
        // Path with encoded characters should be properly decoded
        Debug.print(debug_show (HttpParser.URL("http://example.com/%C3%A7a_va", headers).path.original));
        // assert HttpParser.URL("http://example.com/%C3%A7a_va", headers).path.original == "/ça_va";

        // Path without scheme should have a leading slash
        assert HttpParser.URL("path/not/a/path", headers).path.original == "/path/not/a/path";

        // Path with encoded Unicode characters should be properly decoded
        assert HttpParser.URL("/symbols/c%CC%A7%CB%99%E2%88%86a%CC%8A%C2%A8%E2%88%86%C2%B4%CB%86%CB%9A%C3%9F%C2%A8c%CC%A7%C3%9F.pdf", headers).path.original == "/symbols/ç˙∆å¨∆´ˆ˚ß¨çß.pdf";

        // Empty URL should result in root path
        assert HttpParser.URL("", headers).path.original == "/";

        // Just a slash should be the root path
        assert HttpParser.URL("/", headers).path.original == "/";

        // Path in full URL should have a leading slash
        assert HttpParser.URL("http://example.com/path", headers).path.original == "/path";

        // Path in full URL should preserve trailing slash
        assert HttpParser.URL("http://example.com/path/", headers).path.original == "/path/";
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
      "Path Normalization",
      func() {
        // Test normalization of consecutive slashes
        let consecutiveSlashes = HttpParser.URL("http://example.com//a///b////c", headers);
        assert consecutiveSlashes.path.original == "/a/b/c";
        assert consecutiveSlashes.path.array == ["a", "b", "c"];

        // Test normalization with query parameters
        let slashesWithQuery = HttpParser.URL("http://example.com//a///b?q=1", headers);
        assert slashesWithQuery.path.original == "/a/b";
        assert slashesWithQuery.queryObj.original == "q=1";

        // Test normalization with trailing slashes (preserve trailing slash in original but normalize array)
        let withTrailingSlashes = HttpParser.URL("http://example.com/a/b///", headers);
        assert withTrailingSlashes.path.original == "/a/b/";
        assert withTrailingSlashes.path.array == ["a", "b"];
      },
    );

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
        // Root path has an empty array representation
        assert slashUrl.path.array == [];
      },
    );

    test(
      "Path Segment Edge Cases",
      func() {
        // Multiple consecutive slashes in path should be normalized in the original path
        let emptySegments = HttpParser.URL("http://example.com//path///end", headers);
        assert emptySegments.path.original == "/path/end";
        assert emptySegments.path.array == ["path", "end"];

        // Ensure all paths have a leading slash
        let noLeadingSlash = HttpParser.URL("http://example.com/path", headers);
        assert noLeadingSlash.path.original == "/path";

        // Trailing slash is preserved
        let trailingSlash = HttpParser.URL("http://example.com/path/", headers);
        assert trailingSlash.path.original == "/path/";
        // Normalize array by removing empty segment while preserving slash in original
        assert trailingSlash.path.array == ["path"];

        // Multiple trailing slashes should be normalized to a single trailing slash
        // (preserving the trailing slash semantic meaning in original but normalizing the array)
        let multiTrailing = HttpParser.URL("http://example.com/path///", headers);
        assert multiTrailing.path.original == "/path/";
        // Normalize the array by removing empty trailing segments
        assert multiTrailing.path.array == ["path"];

        // Encoded slash should be decoded correctly
        let encodedSlash = HttpParser.URL("http://example.com/path%2Fsubpath", headers);
        assert encodedSlash.path.original == "/path/subpath";
        assert encodedSlash.path.array == ["path", "subpath"];

        // Relative path should be normalized with leading slash
        let relativePath = HttpParser.URL("path/to/resource", headers);
        assert relativePath.path.original == "/path/to/resource";
        assert relativePath.path.array == ["path", "to", "resource"];
      },
    );

    test(
      "Special Characters Edge Cases",
      func() {
        // Special characters in path
        let specialChars = HttpParser.URL("http://example.com/ !@$%^&*()_+-=[]{}|;:'\",<.>/?", headers);
        // Ensure path starts with / and consecutive slashes are normalized
        assert specialChars.path.original == "/ !@$%^&*()_+-=[]{}|;:'\",<.>/";

        // Unicode characters in path segments
        let unicodeChars = HttpParser.URL("http://example.com/🌟/✨/🎉", headers);
        assert unicodeChars.path.original == "/🌟/✨/🎉";
        assert unicodeChars.path.array == ["🌟", "✨", "🎉"];

        // Mixed encoding with percent-encoded Unicode
        let mixedEncoding = HttpParser.URL("http://example.com/%F0%9F%8C%9F/%E2%9C%A8/%F0%9F%8E%89", headers);
        assert mixedEncoding.path.original == "/🌟/✨/🎉";
        assert mixedEncoding.path.array == ["🌟", "✨", "🎉"];

        // Null bytes in path
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

suite(
  "Host from Headers Tests",
  func() {
    test(
      "Host from Headers - Basic",
      func() {
        let headers = Headers([("host", "example.com")]);
        let url = HttpParser.URL("/path", headers);
        assert url.protocol == "https";
        assert url.host.original == "example.com";
        assert url.host.array == ["example", "com"];
        assert url.port == 443;
        // Check path has leading slash
        assert url.path.original == "/path";
      },
    );

    test(
      "Host from Headers - With Port",
      func() {
        let headers = Headers([("host", "localhost:8080")]);
        let url = HttpParser.URL("/api/v1", headers);
        assert url.host.original == "localhost";
        assert url.host.array == ["localhost"];
        assert url.port == 8080;
        // Check path has leading slash
        assert url.path.original == "/api/v1";
      },
    );

    test(
      "Host from Headers - Subdomain",
      func() {
        let headers = Headers([("host", "api.example.co.uk:3000")]);
        let url = HttpParser.URL("/users", headers);
        assert url.host.original == "api.example.co.uk";
        assert url.host.array == ["api", "example", "co", "uk"];
        assert url.port == 3000;
        // Check path has leading slash
        assert url.path.original == "/users";
      },
    );

    test(
      "Headers vs URL Priority",
      func() {
        let headers = Headers([("host", "from-header.com:8080")]);
        let url = HttpParser.URL("https://from-url.com:9090/path", headers);
        assert url.host.original == "from-url.com";
        assert url.port == 9090;
        assert url.protocol == "https";
        // Check path has leading slash
        assert url.path.original == "/path";
      },
    );

    test(
      "Missing Host Header",
      func() {
        let headers = Headers([]);
        let url = HttpParser.URL("/path", headers);
        assert url.host.original == "";
        assert url.host.array == [];
        assert url.port == 443;
        // Check path has leading slash
        assert url.path.original == "/path";
      },
    );

    test(
      "Empty Host Header",
      func() {
        let headers = Headers([("host", "")]);
        let url = HttpParser.URL("/path", headers);
        assert url.host.original == "";
        assert url.host.array == [];
        // Check path has leading slash
        assert url.path.original == "/path";
      },
    );

    // test(
    //     "Host Header with IPv4",
    //     func() {
    //         let headers = Headers([("host", "127.0.0.1:4000")]);
    //         let url = HttpParser.URL("/path", headers);
    //         assert url.host.original == "127.0.0.1";
    //         assert url.host.array == ["127", "0", "0", "1"];
    //         assert url.port == 4000;
    //         // Check path has leading slash
    //         assert url.path.original == "/path";
    //     },
    // );
  },
);
