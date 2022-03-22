import Text "mo:base/Text";
import HttpParser "mo:HttpParser/Parser";


actor {
    func greet(name : Text) : Text {
        return "Hello, " # name # "!";
    };


    public query func http_request(rawReq: HttpParser.HttpRequest) : async HttpParser.HttpResponse {
        let req = HttpParser.parse(rawReq);

        let name = switch(req.url.queryObj.get("name")){
            case (?name) " " # name;
            case (_) "";
        };

        let result = "<html><head><title> http_request </title></head><body><h1>" # greet(name) # "</h1></body></html>";

        {
            status_code = 200;
            headers = [("Content-Type", "text/html")];
            body = Text.encodeUtf8 (result);
        }
    };
};
