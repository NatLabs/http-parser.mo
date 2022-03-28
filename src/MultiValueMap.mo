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
        public let vals = map.vals;
        public let entries = map.entries;

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

        public func get(key: K): ?[V]{
            switch(map.get(key)){
                case(?buffer){
                    ?buffer.toArray();
                };
                case(_){
                    null;
                };
            }
        };

        // returns a new hashmap with the values stored in immutable arrays instead of buffers
        public func freezeValues(): HashMap.HashMap<K, [V]>{
            let frozenMap = HashMap.HashMap<K, [V]>(size(), keyEq, keyHash);

            for ((key, buffer) in entries()){
                frozenMap.put(key, buffer.toArray());
            };

            return frozenMap;
        };

        // returns a hashmap where only the first value of each entry is stored
        public func toSingleValueMap(): HashMap.HashMap<K, V>{
            let singleValueMap = HashMap.HashMap<K, V>(size(), keyEq, keyHash);

            for ((key, buffer) in entries()){
                singleValueMap.put(key, buffer.get(0));
            };

            return singleValueMap;
        }
    };
};