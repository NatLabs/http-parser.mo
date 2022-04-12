let aviate_labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.3/package-set.dhall sha256:ca68dad1e4a68319d44c587f505176963615d533b8ac98bdb534f37d1d6a5b47
let vessel_package_set =
      https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.20-20220131/package-set.dhall
let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }
let additions = [
  { name = "http"
  , repo = "https://github.com/aviate-labs/http.mo"
  , version = "v0.1.0"
  , dependencies = [ "base" ]
  },
  { name = "format"
  , repo = "https://github.com/tomijaga/format.mo"
  , version = "main"
  , dependencies = [ "base" ]
  },
  { name = "array"
  , repo = "https://github.com/aviate-labs/array.mo"
  , version = "main"
  , dependencies = [ "base" ]
  },
] : List Package
in  aviate_labs # vessel_package_set # additions