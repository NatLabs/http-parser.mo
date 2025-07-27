import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Debug "mo:base/Debug";

import Hex "mo:encoding/Hex";
import JSON "mo:json/JSON";

module {
    public func textToNat(txt : Text) : Nat {
        assert (txt.size() > 0);
        let chars = txt.chars();
        var num : Nat = 0;
        for (v in chars) {
            let charToNum = Nat32.toNat(Char.toNat32(v) -48);
            assert (charToNum >= 0 and charToNum <= 9);
            num := num * 10 + charToNum;
        };
        num;
    };

    func charToLowercase(c : Char) : Char {
        if (Char.isUppercase(c)) {
            let n = Char.toNat32(c);

            //difference between the nat32 values of 'a' and 'A'
            let diff : Nat32 = 32;
            return Char.fromNat32(n + diff);
        };

        return c;
    };

    public func toLowercase(text : Text) : Text {
        var lowercase = "";

        for (c in text.chars()) {
            lowercase := lowercase # Char.toText(charToLowercase(c));
        };

        return lowercase;
    };

    public func arrayToBuffer<T>(arr : [T]) : Buffer.Buffer<T> {
        let buffer = Buffer.Buffer<T>(arr.size());
        for (n in arr.vals()) {
            buffer.add(n);
        };
        return buffer;
    };

    public func arraySliceToBuffer<T>(arr : [T], start : Nat, end : Nat) : Buffer.Buffer<T> {
        var i = start;

        let buffer = Buffer.Buffer<T>(end - start);

        while (i < end) {
            buffer.add(arr[i]);
            i += 1;
        };

        return buffer;
    };

    public func arraySliceToText(arr : [Nat8], start : Nat, end : Nat) : Text {
        var i = start;

        var text = "";

        while (i < end) {
            text #= Char.toText(nat8ToChar(arr[i]));
            i += 1;
        };

        text;
    };

    public func nat8ToChar(n8 : Nat8) : Char {
        let n = Nat8.toNat(n8);
        let n32 = Nat32.fromNat(n);
        Char.fromNat32(n32);
    };

    public func charToNat8(char : Char) : Nat8 {
        let n32 = Char.toNat32(char);
        let n = Nat32.toNat(n32);
        let n8 = Nat8.fromNat(n);
    };

    public func enumerate<A>(iter : Iter.Iter<A>) : Iter.Iter<(Nat, A)> {
        var i = 0;
        return object {
            public func next() : ?(Nat, A) {
                let nextVal = iter.next();

                switch nextVal {
                    case (?v) {
                        let val = ?(i, v);
                        i += 1;

                        return val;
                    };
                    case (_) null;
                };
            };
        };
    };

    // A predicate for matching any char in the given text
    func matchAny(text : Text) : Text.Pattern {
        func pattern(c : Char) : Bool {
            Text.contains(text, #char c);
        };

        return #predicate pattern;
    };

    public func trimEOL(text : Text) : Text {
        return Text.trim(text, matchAny("\n\r"));
    };

    public func trimSpaces(text : Text) : Text {
        return Text.trim(text, matchAny("\t "));
    };

    public func trimQuotes(text : Text) : Text {
        return Text.trim(text, #text("\""));
    };

    public func textToBytes(text : Text) : [Nat8] {
        let blob = Text.encodeUtf8(text);
        Blob.toArray(blob);
    };

    public func bytesToText(bytes : [Nat8]) : ?Text {
        Text.decodeUtf8(Blob.fromArray(bytes));
    };

    public func encodeURIComponent(t : Text) : Text {
        var encoded = "";

        for (c in t.chars()) {
            let cAsText = Char.toText(c);
            if (Text.contains(cAsText, matchAny("'()*-._~")) or Char.isAlphabetic(c) or Char.isDigit(c)) {
                encoded := encoded # Char.toText(c);
            } else {
                let hex = Hex.encodeByte(charToNat8(c));
                encoded := encoded # "%" # hex;
            };
        };
        encoded;
    };

    public func subText(value : Text, indexStart : Nat, indexEnd : Nat) : Text {
        if (indexStart == 0 and indexEnd >= value.size()) {
            return value;
        };
        if (indexStart >= value.size()) {
            return "";
        };

        var result : Text = "";
        var i : Nat = 0;
        label l for (c in value.chars()) {
            if (i >= indexStart and i < indexEnd) {
                result := result # Char.toText(c);
            };
            if (i == indexEnd) {
                break l;
            };
            i += 1;
        };

        result;
    };

    // Helper function to check if a character is a valid hexadecimal digit.
    private func isHexDigit(c : Char) : Bool {
        return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
    };

    /**
    * A robust implementation of decodeURIComponent that correctly handles all edge cases,
    * including double-encoding (e.g., %25).
    *
    * It iterates through the source bytes, building a new buffer. When it encounters a '%',
    * it looks ahead two characters, validates them as hex, decodes them, and appends the
    * resulting byte. Otherwise, it appends characters literally.
    */
    public func decodeURIComponent(encoded : Text) : ?Text {
        let sourceBytes = Blob.toArray(Text.encodeUtf8(encoded));
        let decodedBuffer = Buffer.Buffer<Nat8>(sourceBytes.size());
        var i = 0;

        label parseBytes while (i < sourceBytes.size()) {
            let byte = sourceBytes[i];

            // Compare the byte directly with the Nat8 value for '%', which is 37.
            if (byte == (37 : Nat8)) {
                // Check if there are at least two characters to look ahead. This condition
                // is correct and handles sequences at the very end of the string.
                if (i + 2 < sourceBytes.size()) {
                    let char1 = Char.fromNat32(Nat16.toNat32(Nat8.toNat16(sourceBytes[i + 1])));
                    let char2 = Char.fromNat32(Nat16.toNat32(Nat8.toNat16(sourceBytes[i + 2])));

                    // Pre-validate that both lookahead characters are valid hex digits.
                    if (isHexDigit(char1) and isHexDigit(char2)) {
                        let hexString = Text.fromChar(char1) # Text.fromChar(char2);
                        switch (Hex.decode(hexString)) {
                            case (#ok(decodedByteBlob)) {
                                // **FIX**: The original code had a fragile `if` condition here.
                                // This version is more direct. A 2-char hex string is guaranteed
                                // to decode to a 1-byte blob. We add the byte and explicitly
                                // continue the loop, preventing any accidental fall-through.
                                decodedBuffer.add(decodedByteBlob[0]);
                                i += 3; // Advance index past the '%' and the two hex digits.
                                continue parseBytes;
                            };
                            case (#err(_)) {
                                // This case remains unreachable because of the `isHexDigit` guard.
                                // If it were ever reached, it would indicate a fundamental logic error.
                                // Trapping is a safe response to an impossible state.
                                Debug.trap("Unreachable: Hex.decode failed on a pre-validated string.");
                            };
                        };
                    };
                };
                // If the '%' is not followed by two valid hex digits (due to string end or
                // invalid characters), we fall through to here and treat it as a literal.
                decodedBuffer.add(byte);
                i += 1;
            } else {
                // Not a '%', so just add the byte literally.
                decodedBuffer.add(byte);
                i += 1;
            };
        };

        return Text.decodeUtf8(Blob.fromArray(Buffer.toArray(decodedBuffer)));
    };

};
