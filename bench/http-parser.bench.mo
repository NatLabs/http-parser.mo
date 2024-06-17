import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Char "mo:base/Char";
import Text "mo:base/Text";

import Bench "mo:bench";

import HttpParser "../src";

module {
    public func init() : Bench.Bench {
        let bench = Bench.Bench();

        bench.name("HttpParser library");
        bench.description("Benchmarking the performance with 10k calls");

        bench.rows(["HttpParser"]);
        bench.cols(["parseForm()"]);

        let boundary = "----WebKitFormBoundary";

        var body_text = "";

        func add_file(filename : Text, content_type : Text, size : Nat) {
            body_text #= "--" # boundary # "\r\n";
            body_text #= "Content-Disposition: form-data; name=\"file\"; filename=\"" # filename # "\"\r\n";
            body_text #= "Content-Type: " # content_type # "\r\n\r\n";

            for (i in Iter.range(0, size - 1)) {
                if (i % 100 == 0) {
                    body_text #= "\r\n";
                } else {
                    body_text #= "a";
                };
            };

            body_text #= "\r\n";
        };

        for (i in Iter.range(0, 1000)) {
            add_file("file" # debug_show (i) # ".txt", "text/plain", i);
        };

        add_file("file.md", "text/markdown", (10 * 1024));
        add_file("file.c", "text/plain", (1024 ** 2) * 2);
        add_file("file.json", "application/json", (1024 ** 2) * 4);

        // end form
        body_text #= "--" # boundary # "--\r\n";
        let body = Text.encodeUtf8(body_text);

        bench.runner(
            func(row, col) = switch (row, col) {

                case ("HttpParser", "parseForm()") {
                    let #ok(form) = HttpParser.parseForm(body, #multipart(null));
                };

                case (_) {
                    Debug.trap("Should be unreachable:\n row = \"" # debug_show row # "\" and col = \"" # debug_show col # "\"");
                };
            }
        );

        bench;
    };
};
