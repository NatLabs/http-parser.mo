let aviate_labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.4/package-set.dhall sha256:30b7e5372284933c7394bad62ad742fec4cb09f605ce3c178d892c25a1a9722e

let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }
let additions = [
  { name = "base"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "moc-0.7.3"
  , dependencies = [] : List Text
  },
  { name = "base-0.7.3"
  , repo = "https://github.com/dfinity/motoko-base"
  , version = "moc-0.7.3"
  , dependencies = [] : List Text
  },
  { name = "array"
  , repo = "https://github.com/aviate-labs/array.mo"
  , version = "v0.2.1"
  , dependencies = [ "base" ]
  },
  { name = "json"
  , repo = "https://github.com/aviate-labs/json.mo"
  , version = "v0.2.1"
  , dependencies = [ "base" ]
  },
] : List Package
in  aviate_labs # additions