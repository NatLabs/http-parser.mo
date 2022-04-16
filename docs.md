
## API
### ParsedHttpRequest
| Property | Description | Type |
| - | - | - |
| `method` | The http request method  | `Text` | 
| `url` | Parsed Url Object. Decodes URL encoded queries | [URL](#url) |
| `headers` | Parsed headers Object. Places headers entries into a TrieMap| [Header](#header) |
|`body`  | Parsed Body Object. Returns null if the HTTP request is a GET request (method == "GET") | ?[Body](#body) |

### URL
| Property | Description | Type |
| - | - | - |
| `original` | The url string in the HTTP Request | `Text` |
| `protocol` | always **https** | `Text` |
| `port` | URL Port. Default to `443` if it's not defined | `Nat16` |
| `host` | An object with the url host stored as a string and as an array. The array is the result of the string split at every dot.<br/> <br/> ```original = "www.google.com"```<br/> `array =  ["www", "google", "com"]` | `{original: Text; array: [Text]}` |
| `path` | An object with the url paths stored as a string and as an array. The array is the result of the string split at every backslash. <br/>  <br/> `original = "/categories/items/32"`, <br/>```array = ["categories", "items", "32"] ```| `{original: Text; array: [Text]}` |
| `queryObj` | An object for accessing fields and values of a query string | [SearchParams](#searchParams) |
| `anchor` | Everything after the symbol  `#` | `Text` |

#### SearchParams 
| Property | Description | Type |
| - | - | - |
| `original` | The query string sent in the HTTP Request | `Text` |
| `get` | Retrieves a query value | `(Text) -> ?Text` |
| `trieMap` | Stores all the query entries | `TrieMap<Text, Text>` |
| `keys` | An array with all the field keys | `Text` |

### Header
| Property | Description | Type |
| - | - | - |
| `original` | The Header entries from the HTTP Request | `[(Text, Text)]` |
| `get` | Retrieves header value | `(Text) -> ?Text` |
| `trieMap` | A TrieMap where the value is an array for storing duplicates or header fields with multiple values  | `TrieMap<Text, [Text]>` |
| `keys` | An array with all the header keys | `[Text]` |

### Body 
| Property | Description | Type |
| - | - | - |
| `original` | Blob sent in HTTP Request | `Blob` |
| `size` | Size of blob | `Nat` |
| `text` | Tries to decode the blob as UTF-8. Returns an empty string ("") if the blob is not valid UTF-8.   | `() -> Text` |
| `deserialize` | Tries to decode the blob as JSON. Returns a `null` value if the blob is not valid JSON   | `() -> `[JSON](https://github.com/aviate-labs/json.mo/blob/main/src/JSON.mo#L13) |
| `file` | Returns the blob as bytes if it is not valid form-data/urlencoded format.  | `() -> Buffer<Nat8>` |
| `bytes` | Returns the specified bytes from the blob | `(start: Text, end: Text) -> Buffer<Nat8>` |
| `form` | The files and fields formatted as form data or url encoded pairs in the blob  | [Form](#form) |

#### Form 
| Property | Description | Type |
| - | - | - |
| `get` | Retrieves field values | `(Text) -> ?[Text]` |
| `keys` | An array of all field keys | `[Text]` |
| `trieMap` | Stores all field entries (data without a filename) | `TrieMap<Text, [Text]>` |
| `fileKeys` | An array of all file keys | `[Text]` |
| `files` | Retrieves files of a specific key/name | `(Text) -> ?[`[File](#file)`]` |

#### File
| Property | Description | Type |
| - | - | - |
| `name` | The files key | `Text` |
| `filename` | The name of file as stored on your device | `Text` |
| `mimeType` | MIME Type of the file | `Text` |
| `mimeSubType` | MIME subType of the file | `Text` |
| `start` | The index where the file begins in the blob | `Nat` |
| `end` | The index where the file ends in the blob | `Nat` |
| `bytes` | Returns the File data as bytes | `Buffer<Nat8>` |

