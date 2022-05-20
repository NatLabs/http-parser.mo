import Types "Types";
import Http "mo:http/Http";
import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Blob "mo:base/Blob";

module{
    type ResponseFunctor = {
        status_code: (Http.StatusCode) -> ResponseFunctor;
        header: (Text, Text) -> ResponseFunctor;
        body: (Blob) -> ResponseFunctor;
        bodyFromText: (Text) -> ResponseFunctor;
        bodyFromArray: ([Nat8]) -> ResponseFunctor;
        update: (Bool) -> ResponseFunctor;
        unwrap: () -> Http.Response;
    };

    type ResponseBuildType = {
        status_code: Nat16;
        body: Blob;
        headers: TrieMap.TrieMap<Text, Text>;
        update: Bool;
    };

    public type Response = {
        status_code: Nat16;
        body: Blob;
        headers: [(Text, Text)];
        update: ?Bool;
    };

    public func Builder(): ResponseFunctor{
        let defaultResponse:ResponseBuildType = {
            status_code = 200;
            headers = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
            body = Text.encodeUtf8("");
            update = false;
        };

        functor(defaultResponse)
    };

    func functor(response: ResponseBuildType): ResponseFunctor {
        object {
            public func status_code(status: Http.StatusCode): ResponseFunctor{
                functor({
                    status_code = status;
                    headers = response.headers;
                    body = response.body;
                    update = response.update;
                })
            };

            public func header(field: Text, value: Text): ResponseFunctor {
                response.headers.put(field, value);
                functor(response)
            };

            public func body(payload: Blob): ResponseFunctor{
                functor({
                    status_code = response.status_code;
                    headers = response.headers;
                    body = payload;
                    update = response.update;
                })
            };

            public func bodyFromArray(arr: [Nat8]): ResponseFunctor{
                let payload = Blob.fromArray(arr);
                body(payload);
            };

            public func bodyFromText(text: Text): ResponseFunctor{
                let payload = Text.encodeUtf8(text);
                body(payload);
            };

            public func update(activate: Bool): ResponseFunctor{
                functor({
                    status_code = response.status_code;
                    headers = response.headers;
                    body = response.body;
                    update = activate;
                })
            };

            public func unwrap(): Http.Response{
                {
                    status_code = response.status_code;
                    headers = Iter.toArray(response.headers.entries());
                    body = response.body;
                    update = if (response.update) {?true} else {null};
                }
            };
        }
    };
}