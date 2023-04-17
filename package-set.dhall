let aviate_labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.3/package-set.dhall sha256:ca68dad1e4a68319d44c587f505176963615d533b8ac98bdb534f37d1d6a5b47

let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }
let packages = [
  { name = "base", 
    repo = "https://github.com/dfinity/motoko-base", 
    version = "moc-0.8.6", 
    dependencies = [] : List Text
  },
  { name = "format", 
    repo = "https://github.com/tomijaga/format.mo", 
    version = "main", 
    dependencies = [ "base" ]
  },
  { name = "array", 
    repo = "https://github.com/aviate-labs/array.mo", 
    version = "v0.2.1", 
    dependencies = [ "base" ]
  },
] : List Package

in  aviate_labs # packages