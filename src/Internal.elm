module Internal exposing (Error(..), WebhookToken, sendString, toToken)

import Http
import Json.Decode as D
import Json.Encode as E


{-| The webhook token stores all values needed to access the Matrix-Webhook API.
-}
type WebhookToken
    = WebhookToken
        { apiKey : String
        , url : String
        , roomId : String
        }


{-| If you know where to find the API and what API key to use, you can create a
WebhookToken using this function.

    type Msg = WhResp (Result Error ())

    token : WebhookToken
    token =
        toToken
            { apiKey = "your-api-key"
            , url = "https://example.org"
            , roomId = "!abcdefghijklmnop:example.org"
            }

    sendString WhResp token "hi mom!"

-}
toToken : { apiKey : String, url : String, roomId : String } -> WebhookToken
toToken =
    WebhookToken


{-| Turn any given message into a `Cmd` to send it to the Webhook API.
-}
sendString : (Result Error () -> msg) -> WebhookToken -> String -> Cmd msg
sendString onResponse token message =
    case token of
        WebhookToken t ->
            let
                body : Http.Body
                body =
                    [ ( "text", E.string message )
                    , ( "body", E.string message )
                    , ( "key", E.string t.apiKey )
                    , ( "room_id", E.string t.roomId )
                    ]
                        |> E.object
                        |> Http.jsonBody
            in
            Http.request
                { method = "POST"
                , headers = []
                , url = buildUrl t.url t.roomId
                , body = body
                , expect = expectValues onResponse
                , timeout = Nothing
                , tracker = Nothing
                }


{-| Helper function to deal with trailing slashes between the hostname and the path.
-}
buildUrl : String -> String -> String
buildUrl base roomId =
    if String.endsWith "/" base then
        base ++ roomId

    else
        base ++ "/" ++ roomId


{-| Expect function indicating how to interpret the HTTP request.
-}
expectValues : (Result Error () -> msg) -> Http.Expect msg
expectValues toMsg =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.Timeout_ ->
                    Err WebhookTimeoutError

                Http.NetworkError_ ->
                    Err NetworkError

                Http.BadUrl_ url ->
                    Err (BadUrl url)

                Http.BadStatus_ metadata body ->
                    handleResponse metadata body

                Http.GoodStatus_ metadata body ->
                    handleResponse metadata body


{-| When received a response, decode it.
-}
handleResponse : Http.Metadata -> String -> Result Error ()
handleResponse metadata body =
    if metadata.statusCode == 200 then
        Ok ()

    else
        case D.decodeString (responseDecoder metadata.statusCode) body of
            Ok err ->
                Err err

            Err _ ->
                Err WebhookReturnedInvalidJSON


{-| Given a status code, return a decoder.
-}
responseDecoder : Int -> D.Decoder Error
responseDecoder statusCode =
    case statusCode of
        400 ->
            D.map
                (\ret ->
                    case ret of
                        "I need a json dict with text & key" ->
                            WebhookMissingInput

                        "Invalid JSON" ->
                            WebhookMissingInput

                        "Missing text and/or API key property" ->
                            WebhookMissingInput

                        "Unknown formatter" ->
                            WebhookMissingInput

                        "Missing body" ->
                            WebhookMissingInput

                        "Missing key" ->
                            WebhookMissingInput

                        "Missing room_id" ->
                            WebhookMissingInput

                        "Missing body, key" ->
                            WebhookMissingInput

                        "Missing body, room_id" ->
                            WebhookMissingInput

                        "Missing key, room_id" ->
                            WebhookMissingInput

                        "Missing body, key, room_id" ->
                            WebhookMissingInput

                        _ ->
                            HomeserverReturnedError 400 ret
                )
                (D.field "ret" D.string)

        401 ->
            D.map
                (\ret ->
                    case ret of
                        "I need the good \"key\"" ->
                            Unauthorized

                        "Invalid API key" ->
                            Unauthorized

                        "Invalid SHA-256 HMAC digest" ->
                            Unauthorized

                        _ ->
                            HomeserverReturnedError 401 ret
                )
                (D.field "ret" D.string)

        403 ->
            D.map (HomeserverReturnedError 403) (D.field "ret" D.string)

        404 ->
            D.map
                (\ret ->
                    case ret of
                        "I need the id of the room as a path, and to be in this room" ->
                            NotJoinedToRoom

                        _ ->
                            HomeserverReturnedError 404 ret
                )
                (D.field "ret" D.string)

        504 ->
            D.map
                (\ret ->
                    case ret of
                        "Homeserver not responding" ->
                            HomeserverTimeoutError

                        _ ->
                            HomeserverReturnedError 504 ret
                )
                (D.field "ret" D.string)

        _ ->
            D.map (HomeserverReturnedError statusCode) (D.field "ret" D.string)


{-| The type of error explains what went wrong while trying to access the Matrix-Webhook API.

  - `BadUrl` means the provided url was formed badly.
  - `HomeserverReturnedError` means the homeserver refuses to send the message, returning a status code and an error message.
  - `HomeserverTimeoutError` means the homeserver takes too long to respond to the webhook.
  - `NetworkError` means that something went wrong with the connection. The user may have entered a cave or shut off their WiFi.
  - `NotJoinedToRoom` means that the user is not part of the room and that the webhook is unable to join the room.
  - `Unauthorized` means that an invalid Webhook API key was provided.
  - `WebhookMissingInput` means that the Webhook API requires an unknown input. This may happen if a future version requires a certain value that the API does not specify yet.
  - `WebhookReturnedInvalidJSON` means that the Webhook API returned invalid or unexpected JSON objects.
  - `WehookTimeoutError` means that the Webhook API takes too long to respond.

-}
type Error
    = BadUrl String
    | HomeserverTimeoutError
    | HomeserverReturnedError Int String
    | NetworkError
    | NotJoinedToRoom
    | Unauthorized
    | WebhookMissingInput
    | WebhookTimeoutError
    | WebhookReturnedInvalidJSON



{- Version documentation -}
{---> v1.0.0
The API requires the `text` key and the `key` key in the content.
The API requires the roomId to be in the path
The API does not forbid unknown keys.

POTENTIAL ERRORS:
When the input is invalid:
400 { "status": 400, "ret": "I need a json dict with text & key" }
When the API_KEY is wrong or invalid:
401 { "status": 401, "ret": "I need the good \"key\"" }
When the roomId is invalid, not present or the user is not a member of the room:
404 { "status": 404, "ret": "I need the id of the room as a path, and to be in this room" }
-}
{---> v2.0.0
No changes.
-}
{---> v3.0.0
No changes to the required keys.

POTENTIAL ERRORS:
When the JSON doesn't decode or isn't given:
400 { "status": 400, "ret": "Invalid JSON" }
When the text or API key is not given:
400 { "status": 400, "ret": "Missing text and/or API key property" }
When the API_KEY is wrong or invalid:
401 { "status": 401, "ret": "Invalid API key" }
When the Matrix API doesn't allow sending the room message
403 { "status": 403, "ret": <Matrix API message> }
When the homeserver doesn't respond:
504 { "status": 504, "ret": "Homeserver not responding" }
-}
{---> v3.1.0
No changes.
-}
{---> v3.1.1
No changes.
-}
{---> v3.2.0
The `key` key can now be passed as a parameter.
The `body` key is now the new default for the content. If not present, it will take the `text` key.
The API now accepts `room_id` as a key or a parameter.
The API now supports formatters for certain events.
The API now accepts `digest` as a key. If the API_KEY digests to this value, the request is also considered valid.

POTENTIAL ERRORS:
When the given formatter is not valid:
400 { "status": 400, "ret": "Unknown formatter" }
When the digest value is incorrect:
401 { "status": 401, "ret": "Invalid SHA-256 HMAC digest" }
When certain values are missing:
400 { "status": 400, "ret": "Missing body" }
400 { "status": 400, "ret": "Missing key" }
400 { "status": 400, "ret": "Missing room_id" }
400 { "status": 400, "ret": "Missing body, key" }
400 { "status": 400, "ret": "Missing body, room_id" }
400 { "status": 400, "ret": "Missing key, room_id" }
400 { "status": 400, "ret": "Missing body, key, room_id" }
-}
{---> v3.2.1
No changes.
-}
{---> v3.3.0
No changes.

POTENTIAL ERRORS:
When the webhook API does not recognize the server's error, they pass it on in the response:
<any> { "status": <any>, "ret": <any> }
-}
{---> v3.4.0
No changes.
-}
{---> v3.5.0
No changes.
-}
