import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Text "mo:base/Text";

import ArrayModule "mo:array/Array";
import Hex "mo:encoding/Hex";
import Query "mo:http/Query";
import JSON "mo:json/JSON";
import F "mo:format";

// import HttpParser "lib";

module {
    public func textToNat( txt : Text) : Nat {
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

    func charToLowercase(c: Char): Char{
        if (Char.isUppercase(c)){
            let n = Char.toNat32(c);

            //difference between the nat32 values of 'a' and 'A'
            let diff:Nat32 = 32;
            return Char.fromNat32( n + diff);
        };

        return c;
    };

    public func toLowercase(text: Text): Text{
        var lowercase = "";

        for (c in text.chars()){
            lowercase:= lowercase # Char.toText(charToLowercase(c));
        };

        return lowercase;
    };

    public func arrayToBuffer <T>(arr: [T]): Buffer.Buffer<T>{
        let buffer = Buffer.Buffer<T>(arr.size());
        for (n in arr.vals()){
            buffer.add(n);
        };
        return buffer;
    };

    public func arraySliceToBuffer<T>(arr: [T], start: Nat, end: Nat): Buffer.Buffer<T>{
        let slice = ArrayModule.slice(arr, start, end);
        let buffer = arrayToBuffer<T>(slice);
        return buffer;
    };

    public func n8ToChar(n8: Nat8): Char{
        let n = Nat8.toNat(n8);
        let n32 = Nat32.fromNat(n);
        Char.fromNat32(n32);
    };

    public func enumerate<A>(iter: Iter.Iter<A> ): Iter.Iter<(Nat, A)> {
        var i =0;
        return object{
            public func next ():?(Nat, A) {
                let nextVal = iter.next();

                switch nextVal {
                    case (?v) {
                        i+= 1;
                        ?(i-1, v)
                        };
                    case (_) null;
                };
            };
        };
    };

    public func trimEOL(text: Text): Text{
        func pattern(c: Char): Bool{
            Text.contains("\n\r", #char c);
        };
        return Text.trim(text, #predicate(pattern));
    };

    public func trimSpaces(text: Text): Text{
        func pattern(c: Char): Bool{
            Text.contains("\t ", #char c);
        };
        return Text.trim(text, #predicate(pattern));
    };

    public func trimQuotes(text: Text): Text{
        return Text.trim(text, #text("\""));
    };

    public func bytesToText(bytes:[Nat8]): ?Text {
        Text.decodeUtf8(Blob.fromArray(bytes))
    };

    public func encodeURIComponent(url: Text): Text{
        ""
    };

    public func decodeURIComponent(url: Text): Text{
        ""
    };

    
}