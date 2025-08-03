import Debug "mo:base/Debug";
import Nat16 "mo:base/Nat16";
import Option "mo:base/Option";
import Text "mo:base/Text";

// import HttpParser "mo:http-parser";
import HttpParser "../src";

actor {
    func greet(name : Text) : Text {
        "Hello, " # name # "! ";
    };

    public query func http_request(rawReq : HttpParser.HttpRequest) : async HttpParser.HttpResponse {

        let req = HttpParser.parse(rawReq);
        debugRequestParser(req);

        let { url } = req;
        let { path } = url;

        switch (req.method, path.original) {
            case ("GET", "/") {
                let optName = url.queryObj.get("name");
                let name = Option.get(optName, "");
                {
                    status_code = 200;
                    headers = [];
                    body = Text.encodeUtf8(htmlPage(name));
                };
            };
            case (_) {
                {
                    status_code = 404;
                    headers = [];
                    body = Text.encodeUtf8("Page Not Found");
                };
            };
        };
    };

    func htmlPage(name : Text) : Text {
        "<html><head><title> http_request </title></head><body><h1>" # greet(name) # "</h1><br><form \"multipart/form-data\" action=\".\" >\n    <div><label for=\"fname\">First Name</label>\n    <input type=\"text\" id=\"fname\" name=\"firstname\" placeholder=\"Your name..\"></div>\n\n    <div><label for=\"lname\">Last Name</label>\n    <input type=\"text\" id=\"lname\" name=\"lastname\" placeholder=\"Your last name..\"></div>\n\n    <div><label for=\"country\">Country</label>\n    <select id=\"country\" name=\"country\">\n      <option value=\"australia\">Australia</option>\n      <option value=\"canada\">Canada</option>\n      <option value=\"usa\">USA</option>\n    </select></div>\n\n  <div><label for=\"files\">Files</label>\n <input id=\"files\" multiple type=\"file\" > \n  <input  type=\"submit\" value=\"Submit\"></div>\n  </form>\n <script>\nconst form = document.querySelector(\"form\")\n const handleSubmit = (e)=>{\n e.preventDefault() \nvar input = document.querySelector(\'input[type=\"file\"]\')\n\nvar data = new FormData(form)\ndata.append(\'file\', input.files[0])\ndata.append(\'file\', input.files[1])\ndata.append(\'duplicate-field\', \"value1\")\ndata.append(\'duplicate-field\', \"value3\")\ndata.append(\'Duplicate-field\', \"value2\")\n\nfetch(\'.\', {\n  method: \'POST\',\nheaders:{\n    \"duplicate-header\":\"john\",\n    \"Duplicate-Header\":\"fred\",\n},\n  body: data\n}).then(res=>res.text())\n\n}\n form.addEventListener(\"submit\", handleSubmit)</script></body></html>\n";
    };

    func debugRequestParser(req : HttpParser.ParsedHttpRequest) : () {
        Debug.print("Method (" # debug_show (req.method) # ")");
        Debug.print("\n");

        let { host; port; protocol; path; queryObj; anchor; original = url } = req.url;

        Debug.print("URl (" # debug_show (url) # ")");

        Debug.print("Protocol (" # debug_show (protocol) # ")");

        Debug.print("Host (" # debug_show (host.original) # ")");
        Debug.print("Host (" # debug_show (host.array) # ")");

        Debug.print("Port (" # debug_show (Nat16.toNat(port)) # ")");

        Debug.print("Path (" # debug_show (path.original) # ")");
        Debug.print("Path (" # debug_show (path.array) # ")");

        for ((key, value) in queryObj.trieMap.entries()) {
            Debug.print("Query (" # debug_show (key) # ": " # debug_show (value) # ")");
        };

        Debug.print("Anchor (" # debug_show (anchor) # ")");

        Debug.print("\n");
        Debug.print("Headers");
        let { keys = headerKeys; get = getHeader } = req.headers;
        for (headerKey in headerKeys.vals()) {
            let values = Option.get(getHeader(headerKey), []);
            Debug.print("Header (" # debug_show (headerKey) # ": " # debug_show (values) # ")");
        };

        Debug.print("\n");
        Debug.print("Body");

        switch (req.body) {
            case (?body) {

                Debug.print("Form");
                let { keys; get = getField; files = getFiles; fileKeys } = body.form;
                for (name in keys.vals()) {
                    let values = Option.get(getField(name), []);
                    Debug.print(
                        "Field (" # debug_show (name) # ": " # debug_show (values) # ")"
                    );
                };

                for (name in fileKeys.vals()) {
                    switch (getFiles(name)) {
                        case (?files) {
                            for (file in files.vals()) {

                                Debug.print(
                                    "File (" # debug_show (name) # ": filename: \"" # debug_show (file.filename) # "\", mime: \"" # debug_show (file.mimeType) # "/" # debug_show (file.mimeSubType) # "\", " # debug_show (file.bytes.size()) # " bytes from [start: " # debug_show (file.start) # ", end: " # debug_show (file.end) # "])"
                                );
                            };
                        };
                        case (_) {
                            Debug.print("Error retrieving File");
                        };
                    };
                };
            };
            case (null) {
                Debug.print("no body");
            };
        };
    };
};
