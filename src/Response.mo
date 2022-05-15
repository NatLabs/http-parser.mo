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
        unwrap: () -> Http.Response;
    };

    type ResponseBuildType = {
        status_code: Nat16;
        body: Blob;
        headers: TrieMap.TrieMap<Text, Text>
    };

    public func Builder(): ResponseFunctor{
        let defaultResponse:ResponseBuildType = {
            status_code = 0;
            headers = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
            body = Text.encodeUtf8("");
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

            public func unwrap(): Http.Response{
                {
                    status_code = response.status_code;
                    headers = Iter.toArray(response.headers.entries());
                    body = response.body;
                }
            };
        }
    };
}