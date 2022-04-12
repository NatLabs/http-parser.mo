import Debug "mo:base/Debug";
import Nat16 "mo:base/Nat16";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";

import ArrayModule "mo:array/Array";
import F "mo:format";
import JSON "mo:json/JSON";

import HttpParser "../src/lib";
import Types "../src/Types";
// import DebugModule "../src/Debug";
import ActorSpec "./utils/ActorSpec";

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

func assertIsNull<T>(item: ?T):Bool {
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

            for (key in map1.keys()){

                switch(map1.get(key), map2.get(key)){
                    case(?val1, ?val2){
                        if (not isJsonStrictEqual(val1, val2)){
                            return false;
                        };
                    };
                    case(_, _) return false;
                };
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
        let {url} = HttpParser.parse({url= "https://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/counter/?tag=2526172523#myAnchor"; headers=[]; method= ""; body=Blob.fromArray([]) });

        let {host; port; protocol; path; queryObj; anchor} = url;

        assertAllTrue([
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
        let url = URL("http://localhost:8000/tokens/345");

        let {host; port; protocol; path; queryObj; anchor} = url;

        assertAllTrue([
            protocol == "http",
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
            let body = Body(jsonBlob, ?"application/json");

            let {size; text; form; bytes; file} = body;
            
            let jsonResult = isJsonStrictEqual(
                Option.get(body.deserialize(), #Null),
                #Object(HashMap.fromIter<Text,JSON>(
                    Iter.fromArray<(Text, JSON)>([
                        ("window", #Object(HashMap.fromIter<Text,JSON>(
                            Iter.fromArray<(Text, JSON)>([
                                ("title", #String("Internet Computer Game")),
                                ("name", #String("Dfinity Wars")),
                                ("width", #Number(500)),
                                ("height", #Number(500)),
                            ]), 
                            0,
                            Text.equal,
                            Text.hash
                        )))
                    ]), 
                    0,
                    Text.equal,
                    Text.hash
                )
            ));

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
    ]),
  ]),
]);

if(success == false){
  Debug.trap("Tests failed");
}
