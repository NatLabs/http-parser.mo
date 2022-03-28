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

import Query "mo:http/Query";
import JSON "mo:json/JSON";

import T "types";
import Utils "utils";
import MultiValueMap "MultiValueMap";

module {

    type File = T.File;

    func plainTextIter (blobArray: [Nat8]): Iter.Iter<Char> {
        var i =0;
        return object{
            public func next ():?Char {
                if (i == blobArray.size() ) return null;

                let nextVal = blobArray[i];
                i+=1;

                let n = Nat8.toNat(nextVal);
                let n32 = Nat32.fromNat(n);
                let char = Char.fromNat32(n32);

                return ?char;
            };
        };
    };

    // Todo: add the boundary sent from the content-type as a parameter
    public func parse(blob: Blob): ?HashMap.HashMap<Text, [File]> {
        let blobArray = Blob.toArray(blob);
        let files = MultiValueMap.MultiValueMap<Text, File>(0, Text.equal, Text.hash);
        let chars = plainTextIter(blobArray);

        var boundary = "";
        var closingBoundry = "";

        var row="";
        var text="";

        var rowIndexFromBoundary = 0;
        var contentType = "";
        var name = "";
        var start = 0;
        var end  = 0;
        var prevRowIndex = 0;

        label l for ((i, char) in Utils.enumerate<Char>(chars)){
            row := row # Char.toText(char);
            text := text # Char.toText(char);
          
            
              if (char == '\n') {

                prevRowIndex := i;

                if (rowIndexFromBoundary == 0){
                    if (Text.startsWith(row, #text "--")){
                        boundary:= row;
                        closingBoundry:=boundary #"--";
                        Debug.print("boundary: " # boundary);
                    }else{
                        Debug.print("Error boundary: " # boundary);
                        return null;
                    };
                };

                if (rowIndexFromBoundary == 1){
                    if (Text.startsWith(row, #text "Content-Disposition:")){
                        let iter = Text.split(row, #char ' ');
                        Debug.print(Text.join("-j-",  iter));
                    };
                };

                if (rowIndexFromBoundary == 2){
                    Debug.print("row 2: "#  row);
                };

                if (rowIndexFromBoundary == 3){
                    start := i;
                };

                if (rowIndexFromBoundary == 4){
                    Debug.print("row 4: "#  row);
                };

                if ((row  == boundary or row  == closingBoundry) and boundary != "" ){
                    end:= prevRowIndex-1;
                    Debug.print(name # ": ( "#  Nat.toText(start) # ", " #  Nat.toText(end) # " )");
                    files.add(name, {
                        name = name;
                        filename = name;
                        start = start;
                        end = end;
                        bytes = Utils.sliceArray(blobArray, start, end);
                    });
                    
                    rowIndexFromBoundary := 0;
                    start := 0;
                    end := 0;
                    name := "";
                };
               

                row:= "";

                rowIndexFromBoundary+=1;
            };
        };

        Debug.print("last row: " # row);

        return ?files.freezeValues();
    };
}