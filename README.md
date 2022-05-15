# HTTP Request Parser
A http request parser for parsing url, search query, headers and form data.

## Usage
- Import Module
```motoko
    import HttpParser "mo:HttpParser";
```
- Parse incoming http request
-  ex:  retrieving the `name` field from the url query
```motoko
    import Http "mo:http/Http";
    import HttpParser "mo:HttpParser/Parser";
    import HttpResponse "mo:HttpParser/Response";

    actor {
        public query func http_request(rawReq: Http.Request) : async Http.Response {

            let req = HttpParser.parse(rawReq);
            debugRequestParser(req);

            let { url} = req;
            let { path; queryObj } = url;
            let { Get; Post } = Http.Method;

            switch (req.method, path.original) {
                case (Get, "/"){
                    let optName = queryObj.get("name");
                    let name = Option.get(optName, "");
                    let form = htmlForm(name);

                    HttpResponse.Builder()
                        .status_code(200)
                        .header("Content-Type", "text/html")
                        .body(Text.encodeUtf8(form))
                        .unwrap()
                };
                case(Get, "/form"){
                    HttpResponse.Builder()
                        .status_code(Http.Status.Found)
                        .header("Content-Type", "text/html")
                        .bodyFromText("Redirect to <a href =\"/\"> home page </a>")
                        .unwrap()
                };
                case (Post, "/form"){
                    HttpResponse.Builder()
                        .status_code(Http.Status.OK)
                        .bodyFromText("Your Form has been uploaded successfully!")
                        .unwrap()
                };
                case (_) {
                    HttpResponse.Builder()
                        .status_code(Http.Status.NotFound)
                        .unwrap()
                };
            }
        };

        func htmlForm(name: Text): Text{
            "<h1> Hello, " # name # "! </h1><br><form action=\"/form\" >\n    <div><label for=\"firstname\">First Name</label>\n    <input type=\"text\" id=\"firstname\" name=\"firstname\" placeholder=\"Your name..\"></div>\n\n    <div><label for=\"lastname\">Last Name</label>\n    <input type=\"text\" id=\"lastname\" name=\"lastname\" placeholder=\"Your last name..\"></div>\n\n    </form>";
        };
    };
```

Check out the data types [documentation](./docs.md) for supported fields and methods
