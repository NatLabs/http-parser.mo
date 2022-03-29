import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Result "mo:base/Result";

import Query "mo:http/Query";
import JSON "mo:json/JSON";
import F "mo:format";

import T "types";
import Utils "utils";
import MultiValueMap "MultiValueMap";

module {

    type File = T.File;
    type ParsingError = {
        #MissingExitBoundary;
        #BoundaryNotDetected;
        #IncorrectBoundary;
        #MissingContentName;
    };

    func plainTextIter (blobArray: [Nat8]): Iter.Iter<Char> {
        var i =0;
        return object{
            public func next ():?Char {
                if (i == blobArray.size()) return null;

                let nextVal = blobArray[i];
                i+=1;

                return ?Utils.n8ToChar(nextVal);
            };
        };
    };

    func trimQuotesAndSpaces(text:Text):Text{
        Utils.trimQuotes(Utils.trimSpaces((text)))
    };

    // Format
    // Content-Disposition: form-data; name="myFile"; filename="test.txt"
    func parseContentDisposition(line: Text): (Text, Text) {
        let splitTextArr = Iter.toArray(Text.tokens(line, #char ';'));
        let n = splitTextArr.size();
        var name  = "";
        if (n > 1){
            let arr = Iter.toArray(Text.split(splitTextArr[1], #text("name=")));
            if (arr.size()== 2){
                name:= trimQuotesAndSpaces(arr[1]);
            }; 
        };

        var filename = "";
        if (n > 2){
            let arr = Iter.toArray(Text.split(splitTextArr[2], #text("filename=")));
            if (arr.size() == 2){
                filename:= trimQuotesAndSpaces(arr[1]);
            }; 
        };
        (name, filename)
    };

    // Format
    // Content-Type: text/plain
    func parseContentType(line: Text): (Text, Text){
        let arr = Iter.toArray(Text.tokens(line, #char ':'));

        return if (arr.size() > 1){
            let mime = Iter.toArray(Text.tokens( arr[1], #char '/'));
            let mimeType = mime[0];
            let mimeSubType = if (mime.size() > 1 ){
                mime[1];
            } else {""};

            (mimeType, mimeSubType)
        }else{
            ("", "")
        }
    };

    public func parse(blob: Blob, _boundary:?Text): Result.Result<HashMap.HashMap<Text, [File]>, ParsingError> {
        let blobArray = Blob.toArray(blob);
        let files = MultiValueMap.MultiValueMap<Text, File>(0, Text.equal, Text.hash);
        let chars = plainTextIter(blobArray);

        let delim = "--";
        var boundary = switch(_boundary){
            case (?bound) delim # bound ;
            case (_) "";
        };
        var exitBoundary = if (boundary != "") {boundary # delim} else {""};

        var line="";

        var lineIndexFromBoundary = 0;
        var contentType = "";
        var name = "";
        var filename = "";

        var mimeType = "";
        var mimeSubType = "";

        var start = 0;
        var end  = 0;
        var prevRowIndex = 0;

        label l for ((i, char) in Utils.enumerate<Char>(chars)){
            
            line := Utils.trimSpaces(line # Char.toText(char));
          
            if (char == '\n') {
                // Get's the boundary from the first line if it wasn't specified
                if (lineIndexFromBoundary == 0){
                    if (boundary == ""){
                        if (Text.startsWith(line, #text "--")){
                            boundary:= line;
                            exitBoundary:=boundary # "--";
                            Debug.print("boundary: " # boundary);
                        }else{
                            return #err(#BoundaryNotDetected);
                        };
                    }else{
                        if (boundary != line){
                            return #err(#IncorrectBoundary);
                        };
                    };
                    
                };

                if (lineIndexFromBoundary == 1){
                    if (Text.startsWith(line, #text "Content-Disposition:")){
                        let (_name, _filename) = parseContentDisposition(line);
                        name:= _name;
                        filename := _filename;
                    }else{
                        return #err(#MissingContentName);
                    };
                };

                if (lineIndexFromBoundary == 2){
                    if (Text.startsWith(line, #text "Content-Type:")){
                        let (_mimeType, _mimeSubType) = parseContentType(line);
                        mimeType:= _mimeType;
                        mimeSubType:=_mimeSubType;
                    };
                };

                if (lineIndexFromBoundary == 3){
                    start := i+1;
                };

                if (lineIndexFromBoundary > 1  and (line  == boundary or line  == exitBoundary)){
                    end:= prevRowIndex;
                    files.add(name, {
                        name = name;
                        filename = filename;

                        mimeType = mimeType;
                        mimeSubType = mimeSubType;

                        start = start;
                        end = end;
                        bytes = Utils.sliceArray(blobArray, start, end);
                    });

                    Debug.print(F.format(
                        "name: {}, filename: {} \nmimeType: {}, mimeSubType: {} \n start: {}, end:{}", 
                        [#text name, #text filename, #text mimeType, #text mimeSubType, #num start, #num end]));
                    
                    lineIndexFromBoundary := 0;

                    name := "";
                    filename:="";

                    mimeType := "";
                    mimeSubType := "";

                    start := 0;
                    end := 0;

                };

                if (line  == exitBoundary) {break l};
               

                line:= "";
                prevRowIndex := i;
                lineIndexFromBoundary+=1;
            };
        };

        return #ok(files.freezeValues());
    };
}