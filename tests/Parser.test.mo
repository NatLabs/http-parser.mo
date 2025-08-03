import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Text "mo:base/Text";

import ArrayModule "mo:array/Array";
import JSON "mo:gt-json/JSON";
import { suite; test } "mo:test";

import HttpParser "../src/lib";
import Types "../src/Types";
import Utils "../src/Utils";

let { URL; SearchParams; Headers; Body } = HttpParser;

func isFormEmpty(form : Types.FormObjType) : Bool {
    let { keys; trieMap; fileKeys } = form;
    keys == [] and fileKeys == [] and trieMap.size() == 0;
};

type JSON = JSON.JSON;

func zipIter<A, B>(a : Iter.Iter<A>, b : Iter.Iter<B>) : Iter.Iter<(A, B)> {
    object {
        public func next() : ?(A, B) {
            switch (a.next(), b.next()) {
                case (?valueA, ?valueB) ?(valueA, valueB);
                case (_, _) null;
            };
        };
    };
};

func isJsonStrictEqual(v1 : JSON.JSON, v2 : JSON.JSON) : Bool {
    switch (v1, v2) {
        case (#Number(n1), #Number(n2)) n1 == n2;
        case (#String(s1), #String(s2)) s1 == s2;
        case (#Array(arr1), #Array(arr2)) {
            if (arr1.size() != arr2.size()) return false;
            for ((val1, val2) in zipIter(arr1.vals(), arr2.vals())) {
                if (not isJsonStrictEqual(val1, val2)) return false;
            };
            return true;
        };
        case (#Boolean(bool1), #Boolean(bool2)) bool1 == bool2;
        case (#Object(obj1), #Object(obj2)) {
            if (obj1.size() != obj2.size()) return false;
            for ((key1, val1) in obj1.vals()) {
                for ((key2, val2) in obj2.vals()) {
                    if (key1 == key2) if (not isJsonStrictEqual(val1, val2)) return false;
                };
            };
            return true;
        };
        case (#Null, #Null) true;
        case (_, _) false;
    };
};

suite(
    "HttpParser Tests",
    func() {
        suite(
            "URL Tests",
            func() {
                test(
                    "Successfully parse all fields",
                    func() {
                        let { url; method } = HttpParser.parse({
                            url = "/counter/?tag=2526172523#myAnchor";
                            headers = [("host", "m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app")];
                            method = "GET";
                            body = Blob.fromArray([]);
                        });

                        let { host; port; protocol; path; queryObj; anchor } = url;
                        assert method == "GET";
                        assert protocol == "https";
                        assert port == 443;
                        assert host.original == "m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app";
                        assert host.array == ["m7sm4-2iaaa-aaaab-qabra-cai", "raw", "ic0", "app"];
                        assert path.original == "/counter/";
                        // Normalize the array by removing empty trailing segments
                        assert path.array == ["counter"];
                        assert queryObj.original == "tag=2526172523";
                        assert queryObj.keys == ["tag"];
                        assert queryObj.get("tag") == ?"2526172523";
                        assert Iter.toArray(queryObj.trieMap.entries()) == [("tag", "2526172523")];
                        assert anchor == "myAnchor";
                    },
                );

                test(
                    "Successfully parse local URLs",
                    func() {
                        let headers = Headers([("host", "localhost:8000")]);
                        let url = HttpParser.URL("/tokens/345", headers);

                        let { host; port; protocol; path; queryObj; anchor } = url;
                        assert protocol == "https";
                        assert port == 8000;
                        assert host.original == "localhost";
                        assert host.array == ["localhost"];
                        assert path.original == "/tokens/345";
                        assert path.array == ["tokens", "345"];
                        assert queryObj.keys == [];
                        assert Iter.toArray(queryObj.trieMap.entries()) == [];
                        assert anchor == "";
                    },
                );

                test(
                    "Path normalization tests",
                    func() {
                        let headers = Headers([]);

                        // Test consecutive slashes normalization
                        let consecutiveSlashes = HttpParser.URL("http://example.com//path///to////resource", headers);
                        assert consecutiveSlashes.path.original == "/path/to/resource";
                        assert consecutiveSlashes.path.array == ["path", "to", "resource"];

                        // Test trailing slash preservation in original path but normalization in array
                        let trailingSlash = HttpParser.URL("http://example.com/path/", headers);
                        assert trailingSlash.path.original == "/path/";
                        assert trailingSlash.path.array == ["path"];

                        // Test multiple trailing slashes normalization
                        let multipleTrailingSlashes = HttpParser.URL("http://example.com/path///", headers);
                        assert multipleTrailingSlashes.path.original == "/path/";
                        assert multipleTrailingSlashes.path.array == ["path"];

                        // Test root path
                        let rootPath = HttpParser.URL("http://example.com/", headers);
                        assert rootPath.path.original == "/";
                        assert rootPath.path.array == [];
                    },
                );
            },
        );

        suite(
            "SearchParams Tests",
            func() {
                test(
                    "Parse Query String",
                    func() {
                        let queryObj = SearchParams("?trait-count=11&level=21&species=pisces");
                        assert queryObj.original == "trait-count=11&level=21&species=pisces";
                        assert queryObj.keys == ["trait-count", "level", "species"];
                        assert queryObj.get("trait-count") == ?"11";
                        assert queryObj.get("level") == ?"21";
                        assert queryObj.get("species") == ?"pisces";
                    },
                );

                test(
                    "Returns the last field if it has duplicates",
                    func() {
                        let queryObj = SearchParams("name=Brian&name=Wade&job=Pilot&JOB=Film Director");
                        assert queryObj.keys == ["name", "job", "JOB"];
                        assert queryObj.get("name") == ?"Wade";
                        assert queryObj.get("job") == ?"Pilot";
                        assert queryObj.get("JOB") == ?"Film Director";
                    },
                );

                test(
                    "Decodes URL Encoded pairs",
                    func() {
                        let queryObj = SearchParams("name=Dwayne%20Wade&language=French%26English");
                        assert queryObj.keys == ["name", "language"];
                        assert queryObj.get("name") == ?"Dwayne Wade";
                        assert queryObj.get("language") == ?"French&English";
                    },
                );
            },
        );

        suite(
            "Headers Tests",
            func() {
                test(
                    "Case Insensitive",
                    func() {
                        let headers = Headers([
                            ("Accept", "application/json"),
                            ("Origin", "http://mydomain.com"),
                            ("Cookie", "name=value"),
                        ]);
                        assert headers.keys == ["accept", "origin", "cookie"];
                        assert headers.get("accept") == ?["application/json"];
                        assert headers.get("Origin") == ?["http://mydomain.com"];
                        assert headers.get("COOKIE") == ?["name=value"];
                    },
                );

                test(
                    "Splits comma separated values",
                    func() {
                        let headers = Headers([
                            ("Accept", "application/json"),
                            ("Accept-Encoding", "gzip, deflate"),
                            ("Custom-Header", "value1, value2"),
                        ]);
                        assert headers.keys == ["accept", "accept-encoding", "custom-header"];
                        assert headers.get("accept") == ?["application/json"];
                        assert headers.get("accept-encoding") == ?["gzip", "deflate"];
                        assert headers.get("custom-header") == ?["value1", "value2"];
                    },
                );

                test(
                    "Consolidates duplicated fields",
                    func() {
                        let headers = Headers([
                            ("Accept", "application/json"),
                            ("Accept", "text/plain"),
                            ("Custom-Header", "value1, value2"),
                            ("Custom-Header", "value3"),
                        ]);
                        assert headers.keys == ["accept", "custom-header"];
                        assert headers.get("accept") == ?["application/json", "text/plain"];
                        assert headers.get("custom-header") == ?["value1", "value2", "value3"];
                    },
                );
            },
        );

        suite(
            "Body Tests",
            func() {
                test(
                    "Parse JSON Request Body",
                    func() {
                        let payload = [
                            "{",
                            "\"window\": {",
                            "\"title\": \"Internet Computer Game\",",
                            "\"name\": \"Dfinity Wars\",",
                            "\"width\": 500,",
                            "\"height\": 500",
                            "}",
                            "}",
                        ];

                        let json = Text.join("", Iter.fromArray<Text>(payload));
                        let jsonBlob = Text.encodeUtf8(json);
                        let jsonBytes = Blob.toArray(jsonBlob);
                        let body = Body(jsonBlob, null);

                        let { size; form; bytes } = body;

                        assert body.original == jsonBlob;
                        assert size == jsonBlob.size();
                        assert body.text() == json;
                        assert isFormEmpty(form);

                        assert isJsonStrictEqual(
                            Option.get(body.deserialize(), #Null),
                            #Object([(
                                "window",
                                #Object([
                                    ("title", #String("Internet Computer Game")),
                                    ("name", #String("Dfinity Wars")),
                                    ("width", #Number(500)),
                                    ("height", #Number(500)),
                                ]),
                            )]),
                        );

                        switch (body.file()) {
                            case (?buffer) assert buffer.toArray() == jsonBytes;
                            case (null) assert false;
                        };

<<<<<<< HEAD
                        assert bytes(9, 23).toArray() == ArrayModule.slice(jsonBytes, 9, 23);
                    },
                );
=======
                                queryObj.get("name") == ?"Dwayne Wade",
                                queryObj.get("language") == ?"French&English",
                            ]);
                        },
                    ),

                    it(
                        "Decodes '+' as a space in URL Encoded pairs",
                        do {
                            // This query string uses '+' for spaces, a common encoding method.
                            let queryObj = SearchParams("scope=openid+profile+prometheus:charge&response_type=code");

                            assertAllTrue([
                                queryObj.keys == ["scope", "response_type"],

                                // The core assertion: check that '+' was converted to a space.
                                queryObj.get("scope") == ?"openid profile prometheus:charge",

                                // Also check that the other parameter is still correct.
                                queryObj.get("response_type") == ?"code",
                            ]);
                        },
                    ),

                    it(
                        "Correctly decodes a single layer of percent-encoding (handles 'double encoding')",
                        do {
                            // This query string contains a value that has been URL-encoded twice.
                            // The value 'a b' was first encoded to 'a%20b'.
                            // That result was then encoded again, turning the '%' into '%25',
                            // resulting in 'a%2520b'.
                            // A compliant parser should only decode one layer, resulting in 'a%20b'.
                            let queryObj = SearchParams("value=a%2520b&other=normal");

                            assertAllTrue([
                                // Check that both keys were parsed correctly.
                                queryObj.keys == ["value", "other"],

                                // The core assertion: check that 'a%2520b' was decoded ONCE to 'a%20b'.
                                queryObj.get("value") == ?"a%20b",

                                // Also verify the other parameter is unaffected.
                                queryObj.get("other") == ?"normal",
                            ]);
                        },
                    ),

                    it(
                        "Correctly decodes a valid sequence at the very end of the string",
                        do {
                            // This test directly addresses the concern raised in Comment 1 regarding the
                            // boundary check `i + 2 < sourceBytes.size()`.
                            //
                            // The comment suggested the condition was incorrect and might miss a valid
                            // sequence at the end of the input. This test proves the original logic is
                            // sound by placing a valid percent-encoded sequence (`%2F`) at the exact
                            // end of the string.
                            //
                            // A successful pass confirms the loop condition correctly handles this edge case.
                            let input = "path=a/b%2F";
                            let expected = ?"a/b/";

                            assertAllTrue([
                                // The core assertion: check that the input is decoded correctly.
                                SearchParams(input).get("path") == expected,
                            ]);
                        },
                    ),

                    it(
                        "Treats malformed or incomplete percent-encodings as literal text",
                        do {
                            // This test addresses the concerns from both Comment 2 and Comment 3.
                            //
                            // It verifies that the function's pre-validation logic—the boundary check
                            // (`i + 2 < size`) and the `isHexDigit` check—is working correctly.
                            // When an invalid sequence is found, the function should treat the '%' and
                            // subsequent characters as literals rather than attempting to decode them.
                            //
                            // - For "invalid%2G", the `isHexDigit('G')` check fails.
                            // - For "incomplete%F", the `i + 2 < size` check fails.
                            // - For "trailing%", the `i + 2 < size` check fails.
                            //
                            // By correctly handling these cases *before* calling `Hex.decode`, this test
                            // proves that the `#err` case in the `switch` statement is indeed unreachable,
                            // validating the '/* Unreachable */' comment (addressing Comment 3).
                            // It also shows the fall-through logic correctly results in treating the '%'
                            // as a literal, which is the desired behavior for malformed input (related to Comment 2).
                            assertAllTrue([
                                // Case 1: Invalid hex character
                                Utils.decodeURIComponent("invalid%2G") == ?"invalid%2G",

                                // Case 2: Incomplete sequence (one character)
                                Utils.decodeURIComponent("incomplete%F") == ?"incomplete%F",

                                // Case 3: Trailing '%' with no following characters
                                Utils.decodeURIComponent("trailing%") == ?"trailing%",
                            ]);
                        },
                    ),
                ],
            ),
>>>>>>> main

                test(
                    "Parse URL Encoded Form Data",
                    func() {
                        let payload = [
                            "search=World%20Cup%20Series",
                            "name=Doug Brock",
                            "country=Australia",
                            "search=Permutation%20%26%20Combination",
                        ];

                        let urlEncodedData = Text.join("&", Iter.fromArray<Text>(payload));
                        let blob = Text.encodeUtf8(urlEncodedData);
                        let bytes = Blob.toArray(blob);
                        let body = Body(blob, ?"application/x-www-form-urlencoded");

                        let { form } = body;

                        assert body.original == blob;
                        assert body.size == blob.size();
                        assert body.text() == urlEncodedData;

                        assert form.keys == ["search", "country", "name"];
                        assert form.get("country") == ?["Australia"];
                        assert form.get("name") == ?["Doug Brock"];
                        assert form.get("search") == ?["World Cup Series", "Permutation & Combination"];

                        assert form.fileKeys == [];

                        switch (body.file()) {
                            case (?buffer) assert false;
                            case (null) assert true;
                        };

                        assert body.bytes(9, 23).toArray() == ArrayModule.slice(bytes, 9, 23);
                    },
                );

                test(
                    "Parse Multipart Form Data",
                    func() {
                        let boundary = "boundary";
                        let payload = [
                            "--" # boundary,
                            "Content-Disposition: form-data; name=\"field1\"",
                            "",
                            "value1",
                            "--" # boundary,
                            "Content-Disposition: form-data; name=\"field2\"; filename=\"example.txt\"",
                            "Content-Type: text/plain",
                            "",
                            "value2",
                            "--" # boundary # "--",
                        ];

                        let formData = Text.join("\n", Iter.fromArray<Text>(payload)) # "\n";
                        let blob = Text.encodeUtf8(formData);
                        let blobArray = Blob.toArray(blob);

                        let body = HttpParser.Body(blob, ?"multipart/form-data");
                        let { form } = body;

                        assert body.original == blob;
                        assert body.size == blob.size();
                        assert body.text() == formData;

                        assert form.keys == ["field1"];
                        assert form.get("field1") == ?["value1"];

                        assert form.fileKeys == ["example.txt"];

<<<<<<< HEAD
                        switch (form.files("example.txt")) {
                            case (?arr) {
                                let file = arr[0];
                                assert file.name == "field2";
                                assert file.filename == "example.txt";
                                assert file.mimeType == "text";
                                assert file.mimeSubType == "plain";
                                assert file.start == 172;
                                assert file.end == 178;
                                assert file.bytes.toArray() == Utils.textToBytes("value2");
                                assert file.bytes.toArray() == ArrayModule.slice(blobArray, 172, 178);
                            };
                            case (_) assert false;
                        };
                    },
                );
            },
        );
    },
);
=======
                    it(
                        "Parse URL Encoded Form Data",
                        do {
                            let payload = [
                                "search=World%20Cup%20Series",
                                "name=Doug Brock",
                                "country=Australia",
                                "search=Permutation%20%26%20Combination",
                            ];

                            let urlEncodedData = Text.join("&", Iter.fromArray<Text>(payload));
                            let blob = Text.encodeUtf8(urlEncodedData);
                            let bytes = Blob.toArray(blob);
                            let body = Body(blob, ?"application/x-www-form-urlencoded");

                            let { form } = body;

                            Debug.print(debug_show ("original", body.original));
                            Debug.print(debug_show ("size", body.size, blob.size()));
                            Debug.print(debug_show ("text", body.text()));
                            Debug.print(debug_show ("form.keys", form.keys));
                            Debug.print(debug_show ("form.get(\"country\")", form.get("country")));
                            Debug.print(debug_show ("form.get(\"name\")", form.get("name")));
                            Debug.print(debug_show ("form.get(\"search\")", form.get("search")));
                            Debug.print(debug_show ("form.fileKeys", form.fileKeys));
                            Debug.print(
                                debug_show (
                                    "body.file()",
                                    switch (body.file()) {
                                        case (?buffer) ?buffer.size();
                                        case (null) null;
                                    },
                                )
                            );

                            assertAllTrue([
                                body.original == blob,
                                body.size == blob.size(),
                                body.text() == urlEncodedData,

                                form.keys == ["search", "country", "name"],
                                form.get("country") == ?["Australia"],
                                form.get("name") == ?["Doug Brock"],
                                form.get("search") == ?["World Cup Series", "Permutation & Combination"],

                                form.fileKeys == [],

                                switch (body.file()) {
                                    case (?buffer) false;
                                    case (null) true;
                                },

                                body.bytes(9, 23).toArray() == ArrayModule.slice(bytes, 9, 23),
                            ]);
                        },
                    ),

                    it(
                        "Parse Multipart Form Data",
                        do {
                            let boundary = "boundary";
                            let payload = [
                                "--" # boundary,
                                "Content-Disposition: form-data; name=\"field1\"",
                                "",
                                "value1",
                                "--" # boundary,
                                "Content-Disposition: form-data; name=\"field2\"; filename=\"example.txt\"",
                                "Content-Type: text/plain",
                                "",
                                "value2",
                                "--" # boundary # "--",
                            ];

                            let formData = Text.join("\n", Iter.fromArray<Text>(payload)) # "\n";
                            let blob = Text.encodeUtf8(formData);
                            let blobArray = Blob.toArray(blob);

                            let body = HttpParser.Body(blob, ?"multipart/form-data");
                            let { form } = body;

                            assertAllTrue([
                                body.original == blob,
                                body.size == blob.size(),
                                body.text() == formData,

                                form.keys == ["field1"],
                                form.get("field1") == ?["value1"],

                                form.fileKeys == ["example.txt"],

                                switch (form.files("example.txt")) {
                                    case (?arr) {
                                        let file = arr[0];

                                        assertAllTrue([
                                            file.name == "field2",
                                            file.filename == "example.txt",
                                            file.mimeType == "text",
                                            file.mimeSubType == "plain",
                                            file.start == 172,
                                            file.end == 178,
                                            file.bytes.toArray() == Utils.textToBytes("value2"),
                                            file.bytes.toArray() == ArrayModule.slice(blobArray, 172, 178),
                                        ]);
                                    };
                                    case (_) false;
                                },
                            ])

                        },
                    ),
                ],
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("Tests failed");
};
>>>>>>> main
