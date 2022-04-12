import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Result "mo:base/Result";

import JSON "mo:json/JSON";
import ArrayModule "mo:array/Array";

import Types "Types";
import Utils "Utils";
import FormData "form-data";
import MultiValueMap "MultiValueMap";

module HttpRequestParser {
    
    public type HeaderField = Types.HeaderField;
    public type HttpRequest = Types.HttpRequest;
    public type HttpResponse = Types.HttpResponse;
    public type ParsedHttpRequest = Types.ParsedHttpRequest;

    public type File = Types.File;
    public type FormDataType = Types.FormDataType;

    func defaultPort(protocol: Text): Nat16{
        if (protocol == "http"){80} else{443}
    };

    public class URLEncodedPairs(encodedStr: Text){
        let encodedPairs  =  Iter.toArray(Text.tokens(encodedStr, #text("&")));

        let mvMap = MultiValueMap.MultiValueMap<Text, Text>(Text.equal, Text.hash);
        
        for (encodedPair in encodedPairs.vals()) {
            let pair : [Text] = Iter.toArray(Text.split(encodedPair, #char '='));
            if (pair.size()==2){
                mvMap.add(pair[0], pair[1]);
            };
        };

        public let keys = Iter.toArray(mvMap.keys());

        public let toSingleValueMap = mvMap.toSingleValueMap;
        public let multiValueMap = mvMap.freezeValues();

        public func getValues(key: Text): ?[Text]{
            return multiValueMap.get(key);
        };
    };

    public class SearchParams(queryString: Text) {
        public let original = Text.trimStart(queryString, #char('?'));
        
        let pairs: URLEncodedPairs = URLEncodedPairs(original);

        public let trieMap = pairs.toSingleValueMap();
        public let get = trieMap.get;
        public let keys = pairs.keys;
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

        let (_host, _port): (Text, Nat16) = switch(path_iter.next()){
            case(?_authority){
                let authority = Iter.toArray(Text.tokens(_authority, #char(':')));
                switch (authority.size()){
                    case (0) ("", defaultPort(protocol));
                    case (1) (authority[0], defaultPort(protocol));
                    case (_) (authority[0], Nat16.fromNat(Utils.textToNat(authority[1])));
                };
            };
            case(_) ("", defaultPort(protocol));
        };

        public let port = _port;

        public let host = object {
            public let original = _host;
            public let array = Iter.toArray(Text.tokens(_host, #char('.')));
        };

        public let path = object {
            public let array = Iter.toArray(path_iter);
            public let original = "/" # Text.join("/", Iter.fromArray(array));
        };

    };

    public class Headers(headers: [HeaderField]) {
        public let original = headers;
        let mvMap = MultiValueMap.MultiValueMap<Text, Text>(Text.equal, Text.hash);

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

        public let trieMap: TrieMap.TrieMap<Text, [Text]> = mvMap.freezeValues();

        public func get(_key: Text): ?[Text]{
            let key =  Utils.toLowercase(_key);
            return trieMap.get(key);
        };

        public let keys = Iter.toArray(trieMap.keys());
    };

    public func parseForm(blob: Blob, formType: FormDataType): Result.Result<Types.FormObjType, ()> {
        switch(formType){
            case (#multipart(boundary)){

                let parsedForm = FormData.parse(blob, boundary);

                switch(parsedForm){
                    case (#ok(formObj)){
                       return #ok(formObj)
                    };

                    case(#err(errorType)) {
                        let errorMsg = switch(errorType){
                            case(#MissingExitBoundary)  "MissingExitBoundary";
                            case(#BoundaryNotDetected) "BoundaryNotDetected";
                            case(#IncorrectBoundary) "IncorrectBoundary";
                            case(#MissingContentName) "MissingContentName";
                            case(#UTF8DecodeError) "UTF8DecodeError";
                        };

                        Debug.print("Error Message: " # errorMsg);

                        #err
                    };
                };
            };

            case (#urlencoded){
                let blobText = Text.decodeUtf8(blob);
                switch( blobText ){
                    case (?text){
                        let result = object {
                            let pairs = URLEncodedPairs(text);
                            
                            public let keys = pairs.keys;
                            public let trieMap = pairs.multiValueMap;
                            public let get = pairs.getValues;

                            public let fileKeys: [Text] =[];
                            public func files(key: Text):?[File]{
                                return null;
                            };
                        };

                        #ok(result);
                    };
                    case (_){
                        #err
                    };
                };
            };
        }
    };

    func isFormData(_contentType: Text): Bool {
        let contentType = Utils.toLowercase(_contentType);
        Text.startsWith(contentType, #text("multipart/form-data"))
    };

    func isURLEncoded(_contentType: Text): Bool {
        let contentType = Utils.toLowercase(_contentType);
        Text.startsWith(contentType, #text("application/x-www-form-urlencoded"))
    };

    public class Body (blob: Blob, contentType: ?Text){ 
        let blobArray = Blob.toArray(blob);

        public let original = blob;
        public let size = blob.size();

        public func text(): Text {
            Option.get(Text.decodeUtf8(blob), "")
        };

        public func bytes(start: Nat, end: Nat):  Buffer.Buffer<Nat8>{
            let bytesArray = ArrayModule.slice(blobArray, start, end);
            Utils.arrayToBuffer(bytesArray)
        };

        public func deserialize(): ?JSON.JSON{
            JSON.Parser().parse(text())
        };

        let formType: ?FormDataType = switch(contentType){
            case(?conType){
                if (isFormData(conType)) {
                    let splitText = Iter.toArray(Text.tokens(conType, #text("boundary=")));
                    let boundary = if (splitText.size() == 2){
                        ?Text.trim(splitText[1], #text("\""))
                    }else {
                        null
                    };
                    
                    ?#multipart(boundary)
                }else {
                    if (isURLEncoded(conType)){
                        ?#urlencoded
                    }else{
                        null
                    }
                };
            };
            case(_){
               null
            };
        };

        let defaultForm = object {
            public let keys:[Text] = [];
            public let trieMap = TrieMap.TrieMap<Text, [Text]>(Text.equal, Text.hash);
            public let get = trieMap.get;

            public let fileKeys:[Text] =[];
            public func files(t: Text):?[File]{
                return null;
            };
        };

        var isForm = false;
        
        public let form:Types.FormObjType = switch(formType){
            case(?formType){
                switch(parseForm(blob, formType)){
                    case(#ok(formObj)) {
                        isForm:=true;
                        formObj
                    };
                    case(_) {
                        defaultForm
                    };
                }; 
            };
            case(_){
                defaultForm
            };
        };
        
        public func file(): ?Buffer.Buffer<Nat8>{
            switch (isForm){
                case (true){
                    return null;
                };
                case (false){
                    return ?Utils.arrayToBuffer(blobArray)
                };
            };
        };
    };

    public func parse (req: HttpRequest): Types.ParsedHttpRequest = object {
        public let method = req.method;
        public let url: URL = URL(req.url);
        public let headers: Headers = Headers(req.headers);
        public let body: ?Body = if ( method != "GET") {
            let contentTypeValues = headers.get("Content-Type");
            let contentType = switch(contentTypeValues){
                case (?values){
                    Array.find<Text>(values, func (val){
                        if (isFormData(val) or isURLEncoded(val))  {
                            return true;
                        };
                        return false;
                    })
                };
                case (_){
                    null;
                };
            };
            
            ?Body(req.body, contentType)
        } else {
            null
        };
    };
}