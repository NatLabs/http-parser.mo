# HTTP Request Parser

A http request parser for parsing url, search query, headers and form data.

## Usage

- Import Module

```motoko
    import HttpParser "mo:HttpParser";
```

- Parse incoming http request

```motoko
    public query func http_request(rawReq: HttpParser.HttpRequest) : async HttpParser.HttpResponse {

        let req = HttpParser.parse(rawReq);
        debugRequestParser(req);

        let {url} = req;
        let {path} = url;

        switch (req.method, path.original){
            case ("GET", "/"){
                let optName = url.queryObj.get("name");
                let name = Option.get(optName, "");
                {
                    status_code = 200;
                    headers = [];
                    body = Text.encodeUtf8(htmlPage(name));
                }
            };
            case (_){
                {
                    status_code = 404;
                    headers = [];
                    body = Text.encodeUtf8("Page Not Found");
                }
            }
        }
    };
```

Check out the data types [documentation](./docs.md) for supported fields and methods
