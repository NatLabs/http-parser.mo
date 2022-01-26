# HTTP Request Parser

## Usage

```motoko
    public query func http_request(rawReq: HttpRequest) : async HttpResponse {
        let req = HttpRequestParser.parse(rawReq);

        let name = switch(req.queryObj.get("name")){
            case (?name) " " # name;
            case (_) "";
        };

        let result = "<html><head><title> http_request </title></head><body><h1>👋 Hello" # name # ", Welcome to Dfinity! </h1></body></html>";

        {
            status_code = 200;
            headers = [("Content-Type", "text/html")];
            body = Text.encodeUtf8 (result);
        }
    };
```

Check out the [ParsedHttpRequest](./src/types.mo#L9) type for supported fields and methods