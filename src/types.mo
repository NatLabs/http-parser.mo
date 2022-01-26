import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";

module {
    public type ParsedHttpRequest = {
        method: Text;
        url: {
            original: Text;
            protocol: Text ;
            port: Nat16; 
            host: {
                original: Text;
                array: [Text];
            };
            path: {
                original: Text;
                array: [Text];
            };
            queryObj: {
                original: Text;
                get: (Text) -> ?Text;
                hashMap: HashMap.HashMap<Text, Text>;
                keys: [Text]; 
            };
            anchor: Text; 
        };
        headers: {
            original: [(Text, Text)];
            get: (Text) -> ?[Text];
            hashMap: HashMap.HashMap<Text, [Text]>;
            keys: [Text];
        };
        // body: ?{ 
        //     original: Blob;
        //     size: Nat; 
        //     form: { 
        //         get: (Text) -> ?[Text];
        //         hashMap: HashMap.HashMap<Text, [Text]>;
        //         keys: [Text]; 
        //         files: (Text) -> ?[Buffer.Buffer<Nat8>];
        //     };
        //     text: () -> Text; 
        //     file: () -> ?Buffer.Buffer<Nat8>; 
        //     bytes: (start: Nat8, end: Nat8) -> Buffer.Buffer<Nat8>;
        // };
    };      
}