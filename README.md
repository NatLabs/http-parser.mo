# HTTP Request Parser

A http request parser for parsing url, search query, headers and form data.

## Usage

This code snippet shows a simple example of how to retrieve data from a request, handle web routing and build a response using this lib.

- Parse incoming http request
- ex: retrieving the `name` field from the url query

```motoko
    import HttpParser "mo:HttpParser/Parser";
    import HttpResponse "mo:HttpParser/Response";

    // This is an external lib that contains a list of Method types and Status Codes
    // https://github.com/aviate-labs/http.mo
    import Http "mo:http/Http"; 


    actor {
        public query func http_request(rawReq: Http.Request) : async Http.Response {

            let req = HttpParser.parse(rawReq);

            let { url} = req;
            let { path; queryObj } = url;

            let res = HttpResponse.Builder();

            switch (req.method, path.original) {
                case ("GET", "/"){
                    // Retrieves the 'name' field from the url query
                    let optName = queryObj.get("name");
                    let name = Option.get(optName, "");
                    let form = htmlForm(name);

                    res // the status code default to 200
                    .header("Content-Type", "text/html")
                    .body(Text.encodeUtf8(form))
                    .build()
                };
                case("GET", _ ){
                    res
                    .status_code(Http.Status.Found)
                    .header("Content-Type", "text/html")
                    .bodyFromText("Redirect to <a href =\"/\"> home page </a>")
                    .build()
                };
                case ("POST", "/form"){
                    res
                    .bodyFromText("Congratulations, you completed the form!")
                    .build()
                };
                case (_) {
                    res
                    .status_code(Http.Status.NotFound)
                    .build()
                };
            }
        };

        func htmlForm(name: Text): Text{
            "<h1> Hello, " # name # "! </h1><br><form action=\"/form\" >\n    <div><label for=\"firstname\">First Name</label>\n    <input type=\"text\" id=\"firstname\" name=\"firstname\" placeholder=\"Your name..\"></div>\n\n    <div><label for=\"lastname\">Last Name</label>\n    <input type=\"text\" id=\"lastname\" name=\"lastname\" placeholder=\"Your last name..\"></div>\n\n    </form>";
        };
    };
```

Check out the data types [documentation](./docs.md) for supported fields and methods
