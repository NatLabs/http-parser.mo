import Types "Types";
import Http "mo:http/Http";
import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Blob "mo:base/Blob";

module{

    type StreamingStrategy = Types.StreamingStrategy;
    type Response = Types.HttpResponse;

    type ResponseFunctor = {
        status_code: (Http.StatusCode) -> ResponseFunctor;
        header: (Text, Text) -> ResponseFunctor;
        body: (Blob) -> ResponseFunctor;
        bodyFromText: (Text) -> ResponseFunctor;
        bodyFromArray: ([Nat8]) -> ResponseFunctor;
        update: (Bool) -> ResponseFunctor;
        streaming_strategy: (?StreamingStrategy) -> ResponseFunctor;
        unwrap: () -> Http.Response;
    };

    type ResponseBuildType = {
        status_code: Nat16;
        body: Blob;
        headers: TrieMap.TrieMap<Text, Text>;
        update: Bool;
        streaming_strategy: ?StreamingStrategy
    };

    public func Builder(): ResponseFunctor{
        let defaultResponse:ResponseBuildType = {
            status_code = 200;
            headers = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
            body = Text.encodeUtf8("");
            update = false;
            streaming_strategy = null;
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
                    streaming_strategy = response.streaming_strategy;
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
                    streaming_strategy = response.streaming_strategy;
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
                    streaming_strategy = response.streaming_strategy;
                })
            };

            public func streaming_strategy(strategy: ?StreamingStrategy): ResponseFunctor{
                functor({
                    status_code = response.status_code;
                    headers = response.headers;
                    body = response.body;
                    update = response.update;
                    streaming_strategy = strategy;
                })
            };

            public func unwrap(): Http.Response{
                {
                    status_code = response.status_code;
                    headers = Iter.toArray(response.headers.entries());
                    body = response.body;
                    update = if (response.update) {?true} else {null};
                    streaming_strategy = response.streaming_strategy;
                }
            };
        }
    };
}