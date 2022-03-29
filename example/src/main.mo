import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import Blob "mo:base/Blob";

import Parsec "mo:parsec/Parsec";

// import HttpParser "mo:HttpParser";
import HttpParser "../../src";
import FormData "../../src/form-data";
import Utils "../../src/utils"

actor {

    public query func http_request(rawReq: HttpParser.HttpRequest) : async HttpParser.HttpResponse {

        // Debug.print("\nHeaders");
        // for ((key, value) in rawReq.headers.vals()){
        //     Debug.print(key # ": "# value);
        // };

        let req = HttpParser.parse(rawReq);

        switch( req.body){
            case (?body){
                Debug.print( "body (" # Nat.toText(body.size) # " bytes ):  "  );
                switch(body.form.get("file")){
                    case(?f){
                        Debug.print(Utils.trimSpaces(f[0]));
                    };
                };
            };
            case(null){
                Debug.print( "no body"  );
            };
        };

        let b = "";
        
        // Debug.print("names: " # Text.join(" : ", Iter.fromArray(Option.get(req.headers.get("NaMe"), []))));

        let name = switch(req.url.queryObj.get("name")){
            case (?name) " " # name;
            case (_) "no name";
        };

        let result = "<html><head><title> http_request </title></head><body><h1>" # name # "<form \"multipart/form-data\" action=\".\">\n    <label for=\"fname\">First Name</label>\n    <input type=\"text\" id=\"fname\" name=\"firstname\" placeholder=\"Your name..\">\n\n    <label for=\"lname\">Last Name</label>\n    <input type=\"text\" id=\"lname\" name=\"lastname\" placeholder=\"Your last name..\">\n\n    <label for=\"country\">Country</label>\n    <select id=\"country\" name=\"country\">\n      <option value=\"australia\">Australia</option>\n      <option value=\"canada\">Canada</option>\n      <option value=\"usa\">USA</option>\n    </select>\n\n    <label for=\"subject\">Subject</label>\n    <textarea id=\"subject\" name=\"subject\" placeholder=\"Write something..\" style=\"height:200px\"></textarea>\n\n  <label for=\"files\">Files</label>\n <input id=\"files\" type=\"file\" multiple  webkitdirectory directory > \n  <input type=\"submit\" value=\"Submit\">\n  </form></h1></body></html>";
        
        {
            status_code = 200;
            headers = [("Content-Type", "text/html")];
            body = Text.encodeUtf8 (result);
        }
    };

};