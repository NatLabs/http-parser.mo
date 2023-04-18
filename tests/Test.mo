import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat16 "mo:base/Nat16";

import ArrayModule "mo:array/Array";
import JSON "mo:json/JSON";
import ActorSpec "./utils/ActorSpec";

import HttpParser "../src/lib";
import Types "../src/Types";
import Utils "../src/Utils";

let {assertTrue; assertFalse; assertAllTrue; describe; it; skip; pending; run} = ActorSpec;

let { URL; SearchParams; Headers; Body} = HttpParser;

func isFormEmpty(form: Types.FormObjType): Bool {
    let {keys; trieMap; fileKeys; } = form;
    
    keys == [] and
    fileKeys == [] and
    trieMap.size() == 0
};

type JSON = JSON.JSON;

func zipIter<A, B>(a: Iter.Iter<A>, b:Iter.Iter<B>): Iter.Iter<(A, B)>{
    object{
        public func next(): ?(A, B){
            switch(a.next(), b.next()){
                case(?valueA, ?valueB) ?(valueA, valueB);
                case(_, _) null;
            }
        }
    }
};

func assertNull<T>(item: ?T):Bool {
    switch(item){
        case(null) true;
        case(_) false
    };
};

func isJsonStrictEqual(v1: JSON.JSON, v2: JSON.JSON): Bool{
    switch(v1, v2){
        case(#Number(n1), #Number(n2)) n1 == n2;
        case(#String(s1), #String(s2)) s1 == s2;
        case(#Array(arr1), #Array(arr2)) {
            if (arr1.size() != arr2.size()){
                return false;
            };

            for ((val1, val2) in zipIter(arr1.vals(), arr2.vals())){
                if (not isJsonStrictEqual(val1, val2)){
                    return false;
                };
            };
            return true;
        };

        case(#Boolean(bool1), #Boolean(bool2)) bool1 == bool2;
        case(#Object(map1), #Object(map2)){

            if (map1.size() != map2.size()){
                return false;
            };

            for (((k1, v1), (k2, v2)) in zipIter(map1.vals(), map2.vals())){
                if (k1 != k2 or not isJsonStrictEqual(v1, v2)){
                    return false;
                }
            };

            return true;
        };

        case(#Null, #Null) true;
        case(_, _) false;
    };
};

let success = run([
  describe("HttpParser Tests", [
    describe("URL Tests", [
      it("Test 1: Successfully parse all fields", do {
        let {url; method} = HttpParser.parse({url= "/counter/?tag=2526172523#myAnchor"; headers=[("host", "m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app")]; method= "GET"; body=Blob.fromArray([]) });

        let {host; port; protocol; path; queryObj; anchor} = url;
        assertAllTrue([
            method == "GET",
            protocol == "https",
            port == 443, 
            host.original == "m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app",
            host.array == ["m7sm4-2iaaa-aaaab-qabra-cai", "raw", "ic0", "app"],

            path.original == "/counter",
            path.array == ["counter"],

            queryObj.original == "tag=2526172523",
            queryObj.keys == ["tag"],
            queryObj.get("tag")  == ?"2526172523",
            Iter.toArray(queryObj.trieMap.entries()) == [("tag", "2526172523")],
            
            anchor == "myAnchor"
        ]);

      }),

      it("Test 2: Successfully parse all fields", do {
        let headers = HttpParser.Headers([("host", "localhost:8000")]);
        let url = HttpParser.URL("/tokens/345", headers);

        let {host; port; protocol; path; queryObj; anchor} = url;

        assertAllTrue([
            protocol == "https",
            port == 8000, 
            host.original == "localhost",
            host.array == ["localhost"],

            path.original == "/tokens/345",
            path.array == ["tokens", "345"],

            queryObj.keys == [],
            Iter.toArray(queryObj.trieMap.entries()) == [],

            anchor == ""
        ]);

      }),
    ]),

    describe("SearchParams Tests", [
        it("Parse Query String", do {
              let queryObj = SearchParams("?trait-count=11&level=21&species=pisces");

             assertAllTrue([
                queryObj.original == "trait-count=11&level=21&species=pisces",
                queryObj.keys == ["trait-count", "level", "species"],

                queryObj.get("trait-count")  == ?"11",
                queryObj.get("level")  == ?"21",
                queryObj.get("species")  == ?"pisces",
             ])
          }),
          
          it("Returns the first field if it has duplicates", do {
              let queryObj = SearchParams("name=Brian&name=Wade&job=Pilot&JOB=Film Director");

             assertAllTrue([
                queryObj.keys == ["name", "job", "JOB"],

                queryObj.get("name")  == ?"Brian",
                queryObj.get("job")  == ?"Pilot",
                queryObj.get("JOB")  == ?"Film Director",
             ])
          }),

          it("Decodes URL Encoded pairs", do {
              let queryObj = SearchParams("name=Dwayne%20Wade&language=French%26English");

             assertAllTrue([
                queryObj.keys == ["name", "language"],

                queryObj.get("name")  == ?"Dwayne Wade",
                queryObj.get("language")  == ?"French&English",
             ])
          })
    ]),

    describe("Headers Tests", [
        it("Case Insensitive", do {
              let headers = Headers([("Accept", "application/json"), ("Origin", "http://mydomain.com"), ("Cookie", "name=value")]);

             assertAllTrue([
                headers.keys == ["accept", "origin", "cookie"],

                headers.get("accept")  == ?["application/json"],
                headers.get("Origin")  == ?["http://mydomain.com"],
                headers.get("COOKIE")  == ?["name=value"],
             ])
          }),

        it("Splits comma seperated values into an array", do {
              let headers = Headers([("Accept", "application/json"), ("Accept-Encoding", "gzip, deflate"), ("Custom-Header", "value1, value2")]);

             assertAllTrue([
                headers.keys == ["accept", "accept-encoding", "custom-header"],

                headers.get("accept")  == ?["application/json"],
                headers.get("accept-encoding")  == ?["gzip", "deflate"],
                headers.get("custom-header")  == ?["value1", "value2"],
             ])
          }),
          
          it("Consolidates values of duplicated fields", do {
              let headers = Headers([("Accept", "application/json"), ("Accept", "text/plain"), ("Custom-Header", "value1, value2"), ("Custom-Header", "value3")]);

             assertAllTrue([
                headers.keys == ["accept", "custom-header"],
                headers.get("accept")  == ?["application/json", "text/plain"],
                headers.get("custom-header")  == ?["value1", "value2", "value3"]
             ])
          }),
    ]),

    describe("Body Tests", [
        it("Parse JSON Request Body", do {
            let payload = [
                "{",
                    "\"window\": {",
                        "\"title\": \"Internet Computer Game\",",
                        "\"name\": \"Dfinity Wars\",",
                        "\"width\": 500,",
                        "\"height\": 500",
                    "}",
                "}"
            ];

            let json = Text.join("", Iter.fromArray<Text>(payload));

            let jsonBlob = Text.encodeUtf8(json);
            let jsonBytes  = Blob.toArray(jsonBlob);
            let body = Body(jsonBlob, null);

            let {size; text; form; bytes; file} = body;
            
            let jsonResult = isJsonStrictEqual(
                Option.get(body.deserialize(), #Null),
                #Object([
                    ("window", #Object([
                        ("title", #String("Internet Computer Game")),
                        ("name", #String("Dfinity Wars")),
                        ("width", #Number(500)),
                        ("height", #Number(500)),
                    ]))
                ])
            );

            assertAllTrue([
                body.original == jsonBlob,
                size == jsonBlob.size(),
                body.text() == json,
                isFormEmpty(form),
                jsonResult,
                switch(body.file()){
                    case(?buffer) buffer.toArray() == jsonBytes;
                    case(null) false;
                },
                bytes(9, 23).toArray() == ArrayModule.slice(jsonBytes, 9, 23)
            ])
        }),

        it("Parse URL Encoded Form Data", do{
            let payload = [
                "search=World%20Cup%20Series",
                "name=Doug Brock",
                "country=Australia",
                "search=Permutation%20%26%20Combination"
            ];

            let urlEncodedData = Text.join("&", Iter.fromArray<Text>(payload));
            let blob = Text.encodeUtf8(urlEncodedData);
            let bytes  = Blob.toArray(blob);
            let body = Body(blob, ?"application/x-www-form-urlencoded");

            let {form} = body;

            assertAllTrue([
                body.original == blob,
                body.size == blob.size(),
                body.text() == urlEncodedData,

                form.keys  == ["search", "name", "country"],
                form.get("country")  == ?["Australia"],
                form.get("name") == ?["Doug Brock"],
                form.get("search") == ?["World Cup Series", "Permutation & Combination"],

                form.fileKeys == [], 

                switch(body.file()){
                    case(?buffer) false;
                    case(null) true;
                },

                body.bytes(9, 23).toArray() == ArrayModule.slice(bytes, 9, 23)
            ])
        }),

        it("Parse Multipart Form Data", do{
            let boundary = "boundary";
            let payload = [
                "--" # boundary,
                "Content-Disposition: form-data; name=\"field1\"",
                "",
                "value1",
                "--" # boundary,
                "Content-Disposition: form-data; name=\"field2\"; filename=\"example.txt\"",
                "Content-Type: text/plain",
                "",
                "value2",
                "--" # boundary # "--"
            ];

            let formData = Text.join("\n", Iter.fromArray<Text>(payload)) # "\n";
            let blob = Text.encodeUtf8(formData);
            let blobArray = Blob.toArray(blob);

            let body = HttpParser.Body(blob, ?"multipart/form-data");
            let {form} = body;

            assertAllTrue([
                body.original == blob,
                body.size == blob.size(),
                body.text() == formData,

                form.keys == ["field1"],
                form.get("field1") == ?["value1"],
                
                form.fileKeys == ["field2"],

                switch(form.files("field2")){
                    case(?arr){
                        let file = arr[0];

                        assertAllTrue([
                            file.name == "field2",
                            file.filename == "example.txt",
                    
                            file.mimeType == "text",
                            file.mimeSubType == "plain",
                    
                            file.start == 172,
                            file.end == 178,
                            
                            file.bytes.toArray() == Utils.textToBytes("value2"),
                            file.bytes.toArray() == ArrayModule.slice(blobArray, 172, 178)

                        ])
                    };

                    case(_) false;
                }
            ])

        })
    ]),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}
