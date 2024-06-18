// @testmode wasi
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Char "mo:base/Char";
import Text "mo:base/Text";

import Bench "mo:bench";

import HttpParser "../src";

let boundary = "----WebKitFormBoundary";

var body_text = "";

func add_file(filename : Text, content_type : Text, size : Nat) {
    body_text #= "--" # boundary # "\r\n";
    body_text #= "Content-Disposition: form-data; name=\"file\"; filename=\"" # filename # "\"\r\n";
    body_text #= "Content-Type: " # content_type # "\r\n\r\n";

    for (i in Iter.range(0, size - 1)) {
        if (i % 100 == 99) {
            body_text #= "\n";
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

let #ok(form) = HttpParser.parseForm(body, #multipart(null));

for (i in Iter.range(0, 1000)){
    let filename = "file" # debug_show (i) # ".txt";
    let ?files = form.files(filename);

    let file = files[0];
    
    assert (file.mimeType # "/" # file.mimeSubType == "text/plain");
    assert (filename == file.filename);
    assert file.bytes.size() == i;
    assert file.end - file.start == i;
};    

let ?markdown = form.files("file.md");
assert markdown[0].mimeType # "/" # markdown[0].mimeSubType == "text/markdown";
assert markdown[0].filename == "file.md";
assert markdown[0].bytes.size() == (10 * 1024);
assert markdown[0].end - markdown[0].start == (10 * 1024);

let ?c = form.files("file.c");
assert c[0].mimeType # "/" # c[0].mimeSubType == "text/plain";
assert c[0].filename == "file.c";
assert c[0].bytes.size() == (1024 ** 2) * 2;

let ?json = form.files("file.json");
assert json[0].mimeType # "/" # json[0].mimeSubType == "application/json";
assert json[0].filename == "file.json";
assert json[0].bytes.size() == (1024 ** 2) * 4;

