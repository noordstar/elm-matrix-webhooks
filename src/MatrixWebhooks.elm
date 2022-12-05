module MatrixWebhooks exposing (..)

{-| The MatrixWebhooks module helps connect to the [Matrix-Webhook API](https://github.com/nim65s/matrix-webhook).


# Making a request

-}

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
404 { "status": 404, "ret": "I need the id of the room as a path, and to be in this room"}
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
