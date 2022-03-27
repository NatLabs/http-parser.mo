import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Text "mo:base/Text";

import HttpTypes "mo:http/Http";
import Query "mo:http/Query";
import JSON "mo:json/JSON";

import T "types";
import Utils "utils";
import FormData "form-data";
import MVHashMap "MVHashMap";

module HttpRequestParser {
    
    public type HeaderField = HttpTypes.HeaderField;
    public type HttpRequest = HttpTypes.Request;
    public type HttpResponse = HttpTypes.Response;

    type File = T.File;

    func defaultPort(protocol: Text): Nat16{
        if (protocol == "http"){80} else{443}
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

        let p =  Iter.toArray(Text.tokens(url_str, #char('#')));

        public let anchor = if (p.size() > 1){
            url_str := p[0];
            p[1]
        }else {
            url_str := p[0];
            ""
        };

        let re = Iter.toArray(Text.tokens(url_str, #char('?')));

        let queryString: Text = switch (re.size()){
            case (0) {
                url_str := "";
                re[1] 
            };
            case (1){
                url_str := re[0];
                ""
            };

            case (_){
                url_str := re[0];
                re[1]
            };
            
        };

        public let queryObj: SearchParams = SearchParams(queryString);

        let path_iter = Text.tokens(url_str, #char('/')); 

        let authority = if (Iter.size(path_iter) > 0){
            Iter.toArray(Text.tokens(Option.get(path_iter.next(), ""), #char(':')));
        } else{
            []
        };
        
        let (_host, _port): (Text, Nat16) = switch (authority.size()){
            case (0) ("", defaultPort(protocol));
            case (1) (authority[0], defaultPort(protocol));
            case (_) (authority[0], Nat16.fromNat(Utils.textToNat(authority[1])));
        };

        public let host: Host = Host(_host);
        public let port = _port;

        public let path = object {
            public let original = Text.join("/", path_iter);
            public let array = Iter.toArray(path_iter);
        };

    };

    public class Headers(headers: [HeaderField]) {
        public let original = headers;
        let mvMap = MVHashMap.MVHashMap<Text, Text>(headers.size(), Text.equal, Text.hash);

        for ((_key, value) in headers.vals()) {
            let key  = Utils.toLowercase(_key);

            // split and trim comma seperated values 
            let valuesIter = Iter.map<Text, Text>(
                Text.split(value, #char ','), 
                func (text){
                    Text.trim(text, #char ' ')
                });
                
            let values = Iter.toArray(valuesIter);
            mvMap.addMany(key, values);
        };

        public let hashMap: HashMap.HashMap<Text, [Text]> = mvMap.freezeValues();

        public func get(_key: Text): ?[Text]{
            let key =  Utils.toLowercase(_key);
            return hashMap.get(key);
        };

        public let keys = Iter.toArray(hashMap.keys());
    };


    public class Body (blob: Blob, contentType: ?[Text]){ 
        let blobArray = Blob.toArray(blob);

        public let original = blob;
        public let size = blob.size();

        public func text(): Text {
            Option.get(Text.decodeUtf8(blob), "")
        };

        public func bytes(start: Nat, end: Nat):  Buffer.Buffer<Nat8>{
            let bytesArray = Utils.sliceArray<Nat8>(blobArray, start, end);
            Utils.arrayToBuffer(bytesArray)
        };

        public func deserialize(): ?JSON.JSON{
            JSON.Parser().parse(text())
        };

        let parsedForm = FormData.parse(blob);
        
        public func file(): ?Buffer.Buffer<Nat8>{
            switch (parsedForm){
                case (?notNull){
                    return null;
                };
                case (_){
                    return ?Utils.arrayToBuffer(blobArray)
                };
            };
        };

        let emptyFormHashMap = HashMap.HashMap<Text, [File]>(0, Text.equal, Text.hash);
        let formData = Option.get<HashMap.HashMap<Text, [File]>>(parsedForm, emptyFormHashMap);

        public let form = object {
            public let keys = Iter.toArray(formData.keys());

            public func files(name: Text):?[Buffer.Buffer<Nat8>]{
                 switch (formData.get(name)){
                    case (?filesData){
                        let arrOfBytes = Array.map<File, Buffer.Buffer<Nat8>>(filesData, func (file){
                            Utils.arrayToBuffer<Nat8>(file.bytes);
                        });

                        return ?arrOfBytes
                    };
                    case (_) null;
                };
            };

            public let hashMap = HashMap.HashMap<Text, [Text]>(formData.size(), Text.equal, Text.hash);

            for ((key, filesData) in formData.entries()){
                let decodedFiles = Array.map<File, Text>(filesData, func (file){
                    Option.get( Text.decodeUtf8(Blob.fromArray(file.bytes)), "")
                });
                hashMap.put(key, decodedFiles);
            };

            public func get(key: Text): ?[Text]{
                hashMap.get(key)
            };
        };

        
    };

    public func parse (req: HttpRequest): T.ParsedHttpRequest = object {
            public let method = req.method;
            public let url: URL = URL(req.url);
            public let headers: Headers = Headers(req.headers);
            public let body: ?Body = if ( method != "GET") {
                ?Body(req.body, headers.get("Content-Type") ) 
                } else {
                    null
                };
        };
}