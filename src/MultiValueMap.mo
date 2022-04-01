import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";

import Utils "utils";

module {
    // Multi-Value HashMap
    public class MultiValueMap<K, V>(
        initCapacity : Nat,
        keyEq : (K, K) -> Bool,
        keyHash : K -> Hash.Hash
    ){

        let map = HashMap.HashMap<K, Buffer.Buffer<V>>(initCapacity, keyEq, keyHash);

        public let size = map.size;
        public let keys = map.keys;

        public func put(key:K, value:V): () {
            let buffer = Buffer.Buffer<V>(1);
            buffer.add(value);
            map.put(key, buffer);
        };

        public func putMany(key:K, values:[V]): (){
            let buffer = Utils.arrayToBuffer<V>(values);
            map.put(key, buffer);
        };

        public func add(key:K, value:V){
            switch(map.get(key)){
                case (?buffer){
                    buffer.add(value);
                    map.put(key, buffer);
                };
                case (_){
                    put(key, value);
                };
            };
        };

        public func addMany(key:K, values:[V]){
            switch(map.get(key)){
                case (?buffer){
                    buffer.append(Utils.arrayToBuffer<V>(values));
                    map.put(key, buffer);
                };
                case (_){
                    putMany(key, values);
                };
            };
        };


        func optBufferToArray(optionalBuffer: ?Buffer.Buffer<V>):?[V]{
            switch(optionalBuffer){
                case(?buffer){
                    ?buffer.toArray();
                };
                case(_){
                    null;
                };
            }
        };

        public func get(key: K): ?[V]{
            optBufferToArray(map.get(key))
        };

        public func vals(): Iter.Iter<[V]>{
            let iter = map.vals();

            return object {
                public func next(): ?[V]{
                    optBufferToArray(iter.next());
                };
            };
        };

        public func entries(): Iter.Iter<(K, [V])>{
            let iter = map.entries();

            return object {
                public func next(): ?(K, [V]){
                   switch (iter.next()){
                       case (?(key, buffer)){
                           ?(key, buffer.toArray())
                       };
                       case (_){
                           null
                       };
                   };
                };
            };
        };

        // returns a new hashmap with the values stored in immutable arrays instead of buffers
        public func freezeValues(): HashMap.HashMap<K, [V]>{
            HashMap.fromIter<K, [V]>(entries(), size(), keyEq, keyHash);
        };

        // returns a hashmap where only the first value of each entry is stored
        public func toSingleValueMap(): HashMap.HashMap<K, V>{
            let singleValueMap = HashMap.HashMap<K, V>(size(), keyEq, keyHash);

            for ((key, values) in entries()){
                singleValueMap.put(key, values[0]);
            };

            return singleValueMap;
        };

    };
};