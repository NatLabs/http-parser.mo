import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import Blob "mo:base/Blob";

import Parsec "mo:parsec/Parsec";
import F "mo:format";

import HttpParser "mo:HttpParser";
import HttpParserTypes "mo:HttpParser/types";

// import HttpParser "../../src";
import FormData "../../src/form-data";
import Utils "../../src/utils"

actor {
    func greet(name: Text): Text{
        "Hello, " # name  # "! "
    };

    func debugRequestParser(req: HttpParserTypes.ParsedHttpRequest ): (){
        Debug.print(F.format("Method ({})", [#text(req.method)]));
        Debug.print("\n");

        let {host; port; path; queryObj; anchor; original = url} = req.url;

        Debug.print(F.format("URl ({})", [#text(url)]));

        Debug.print(F.format("Host ({})", [#text(host.original)]));
        Debug.print(F.format("Host ({})", [#textArray (host.array)]));

        Debug.print(F.format("Port ({})", [#num(Nat16.toNat(port))]));

        Debug.print(F.format("Path ({})", [#text(path.original)]));
        Debug.print(F.format("Path ({})", [#textArray (path.array)]));

        for ((key, value) in queryObj.hashMap.entries()){   
            Debug.print(F.format("Query ({}: {})", [#text(key), #text(value)]));
        };

        Debug.print(F.format("Anchor ({})", [#text(anchor)]));

        Debug.print("\n");
        Debug.print("Headers");
        let {keys = headerKeys; get = getHeader }= req.headers;
        for (headerKey in headerKeys.vals()){
            let values = Option.get(getHeader(headerKey), []);
                Debug.print(F.format("Header ({}: {})", [#text(headerKey), #textArray(values)]));
        };

        Debug.print("\n");
        Debug.print("Body");

        switch( req.body){
            case (?body){

                Debug.print("Form");
                let {keys; get = getField; files = getFiles; fileKeys} = body.form;
                for (name in keys.vals()){
                    let values = Option.get(getField(name), []);
                    Debug.print( F.format("Field ({}: {})", 
                        [#text(name), #textArray(values) ]) );
                };

                for (name in fileKeys.vals()){
                    switch(getFiles(name)){
                        case(?files){
                            for (file in files.vals()){
                                Debug.print( F.format(
                                    "File ({}: filename: \"{}\", mime: \"{}/{}\", {} bytes)", 
                                    [#text(name), #text(file.filename), #text(file.mimeType), #text(file.mimeSubType), #num(file.bytes.size())]
                                    ) );
                            };
                        };
                        case(_){
                            Debug.print("Error");
                        };
                    };
                };
            };
            case(null){
                Debug.print( "no body" );
            };
        };
    };
    
    public query func http_request(rawReq: HttpParser.HttpRequest) : async HttpParser.HttpResponse {

        let req = HttpParser.parse(rawReq);
        debugRequestParser(req);

        let name = switch(req.url.queryObj.get("name")){
            case (?name) name;
            case (_) "";
        };

        let htmlPage = "<html><head><title> http_request </title></head><body><h1>" # greet(name) # "</h1><br><form \"multipart/form-data\" action=\".\" >\n    <div><label for=\"fname\">First Name</label>\n    <input type=\"text\" id=\"fname\" name=\"firstname\" placeholder=\"Your name..\"></div>\n\n    <div><label for=\"lname\">Last Name</label>\n    <input type=\"text\" id=\"lname\" name=\"lastname\" placeholder=\"Your last name..\"></div>\n\n    <div><label for=\"country\">Country</label>\n    <select id=\"country\" name=\"country\">\n      <option value=\"australia\">Australia</option>\n      <option value=\"canada\">Canada</option>\n      <option value=\"usa\">USA</option>\n    </select></div>\n\n  <div><label for=\"files\">Files</label>\n <input id=\"files\" type=\"file\" > \n  <input type=\"submit\" value=\"Submit\"></div>\n  </form>\n <script>\nconst form = document.querySelector(\"form\")\n const handleSubmit = (e)=>{\n e.preventDefault() \nvar input = document.querySelector(\'input[type=\"file\"]\')\n\nvar data = new FormData(form)\ndata.append(\'file\', input.files[0])\ndata.append(\'field\', \"value1\")\ndata.append(\'field\', \"value2\")\n\n\nfetch(\'.\', {\n  method: \'POST\',\nheaders:{\n    \"duplicate-header\":\"john\",\n    \"Duplicate-Header\":\"fred\",\n},\n  body: data\n}).then(res=>res.text())\n\n}\n form.addEventListener(\"submit\", handleSubmit)</script></body></html>\n";
        
        {
            status_code = 200;
            headers = [("Content-Type", "text/html")];
            body = Text.encodeUtf8 (htmlPage);
        }
    };

};