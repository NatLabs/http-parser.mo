import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import HttpTypes "mo:http/Http";
import Iter "mo:base/Iter";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";

import Query "mo:http/Query";
import Text "mo:base/Text";

import Type "types";

module HttpRequestParser {
  
    public type HeaderField = HttpTypes.HeaderField;
    public type HttpRequest = HttpTypes.Request;

    func textToNat( txt : Text) : Nat {
        assert(txt.size() > 0);
        let chars = txt.chars();
        var num : Nat = 0;
        for (v in chars){
            let charToNum = Nat32.toNat(Char.toNat32(v)-48);
            assert(charToNum >= 0 and charToNum <= 9);
            num := num * 10 +  charToNum;          
        };
        num;
    };

    class Host (hostname: Text){
        public let original = hostname;
        public let array = Iter.toArray(Text.tokens(hostname, #char('.')));
    };

    class EncodedKeyValuePairs(encodedStr: Text){
        let encodedPairs  =  Iter.toArray(Text.tokens(encodedStr, #text("&")));

        public let hashMap = HashMap.HashMap<Text, Text>(encodedPairs.size(), Text.equal, Text.hash);
        
        for (encodedPair in encodedPairs.vals()) {
            let pair : [Text] = Iter.toArray(Text.split(encodedPair, #char '='));
            if (pair.size()==2){
                hashMap.put(pair[0], pair[1]);
            };
        };

        public func get(key: Text): ?Text{
            return hashMap.get(key);
        };

        public let keys = Iter.toArray(hashMap.keys());
    };

    public class SearchParams(queryString: Text) {
        public let original = Text.trimStart(queryString, #char('?'));
        
        let params: EncodedKeyValuePairs = EncodedKeyValuePairs(original);

        public let hashMap = params.hashMap;

        public let get = params.get;
        public let keys = params.keys;
    };

    public class URL (url: Text){
        var url_str = url;  
        let href = url_str;       
        public let original = href;
        
        let (_protocol, str_wp) = switch (Text.stripStart(href, #text "https:")){
            case (?str)  ("https", str);
            case (_) 
                switch (Text.stripStart(href, #text "http:")){
                    case (?str) ("http", str);
                    case (_) ("https", href);
                };
        };

        url_str:=str_wp;

        public let protocol = _protocol;

        let p =   Iter.toArray(Text.tokens(url_str, #char('#')));

        public let anchor = if (p.size() > 1){
            url_str := p[0];
            p[1]
        }else {
            url_str := p[0];
            ""
        };

        let re = Iter.toArray(Text.tokens(url_str, #char('?')));

        let queryString: Text = if (re.size() > 1){
            url_str := re[0];
            re[1]
        }else{
            url_str := re[0];
            ""
        };

        public let queryObj: SearchParams = SearchParams(queryString);

        let path_iter = Text.tokens(url_str, #char('/')); 

        let authority = Iter.toArray(Text.tokens(Option.get(path_iter.next(), ""), #char(':')));
        
        let (_host, _port): (Text, Nat16) = if (authority.size() > 1){
            (authority[0], Nat16.fromNat(textToNat(authority[1])))
        }else{
             (authority[0], if (protocol == "http"){80} else{443})
        };

        public let host: Host = Host(_host);
        public let port = _port;

        public let path = object {
            public let original = Text.join("/", path_iter);
            public let array = Iter.toArray(path_iter);
        };

    };

    public class Headers(headers: [HeaderField]){
        public let original = headers;
        let hashMapWithBuffer = HashMap.HashMap<Text, Buffer.Buffer<Text>>(headers.size(), Text.equal, Text.hash);

        for ((key, value) in headers.vals()) {
            let prevBuffer = hashMapWithBuffer.get(key);
            
            switch(prevBuffer){
                case(?prevBuffer) prevBuffer.add(value);
                case(_){
                    let buffer = Buffer.Buffer<Text>(1);
                    buffer.add(value);
                    hashMapWithBuffer.put(key, buffer);
                };
            };
        };

        public let hashMap = HashMap.HashMap<Text, [Text]>(hashMapWithBuffer.size(), Text.equal, Text.hash);

        for ((key, values) in hashMapWithBuffer.entries()){
            hashMap.put(key, values.toArray());
        };

        public func get(key: Text): ?[Text]{
            return hashMap.get(key);
        };

        public let keys = Iter.toArray(hashMap.keys());
    };


    // public class Body (blob: Blob, contentType: ?[Text]){ 
    //     public let original = blob;

    //     public let size = blob.size();
    // };

    public func parse (req: HttpRequest): Type.ParsedHttpRequest =
        object {
            public let method = req.method;
            public let url: URL = URL(req.url);
            public let headers: Headers = Headers(req.headers);
            // public let body: ?Body = if ( method != "GET") {?Body(req.body, headers.get("Content-Type") ) } else {null};
        }

}