import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import JSON "mo:json/JSON";

module {

    public type File = {
        name: Text;
        filename: Text;
        
        mimeType: Text;
        mimeSubType: Text;

        start: Nat;
        end: Nat;
        bytes: Buffer.Buffer<Nat8>;
    };

    public type FormObjType = {
        get: (Text) -> ?[Text];
        hashMap: HashMap.HashMap<Text, [Text]>;
        keys: [Text]; 
        files: (Text) -> ?[File];
    };

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
        body: ?{ 
            original: Blob;
            size: Nat; 
            form: FormObjType;
            text: () -> Text; 
            deserialize: () -> ?JSON.JSON;
            file: () -> ?Buffer.Buffer<Nat8>; 
            bytes: (start: Nat, end: Nat) -> Buffer.Buffer<Nat8>;
        };
    };      

    // internal types
    

    public type FormDataType = {
        #urlencoded: ();
        
        // takes the boundary as a parameter
        #multipart: ?Text;
    };
}