module Matrix.Webhooks exposing
    ( Webhook, toWebhook
    , sendMessage, sendRaw
    , Error(..)
    )

{-| The MatrixWebhooks module connects to the Matrix-Webhook API.


# Webhook

First, you'll set up a configuration to connect to a webhook.

@docs Webhook, toWebhook


# Sending messages

@docs sendMessage, sendRaw


# Catching errors

@docs Error

-}

import Internal


{-| Webhook that can be connected to.
-}
type alias Webhook =
    Internal.WebhookToken


{-| You can configure access to the webhook using this function.

    webhook : Webhook
    webhook =
        toWebhook
            "https://example.com"
            "your-secret-api-key"
            "!abcdef:example.org"

-}
toWebhook : String -> String -> String -> Webhook
toWebhook url apiKey roomId =
    Internal.toToken
        { apiKey = apiKey
        , url = url
        , roomId = roomId
        }


{-| Send a message to the webhook. The message supports Markdown.

    sendMessage : Cmd msg
    sendMessage toMsg webhook "hi mom!"

It is recommended to use this function to make a smaller one and focus on sending the messages.

    send : String -> Cmd msg
    send = sendMessage toMsg webhook

    -- These all send a message to the Matrix-Webhook API
    send "hi mom!"
    send "I am a **big** adult now."
    send "Are you proud of me? :)"

-}
sendMessage : (Result Error () -> msg) -> Webhook -> String -> Cmd msg
sendMessage expect webhook message =
    Internal.sendString (convert >> expect) webhook message


{-| The previous message is all nicely set up, but some people prefer a simple function where you can insert all your data right away.
This function is relatively careless, allowing you to send message to the Webhook API and only getting a `Bool` in return that lets you know whether the message was sent successfully.

    type Msg = Success Bool

    sendRaw
        Success
        "https://example.com"
        "your-secret-api-key"
        "!abcdef:example.org"
        "hi mom!"
    == sendMessage toMsg webhook "hi mom!"

**Note:** If the function returns `False`, there is no way of finding out why it went wrong.

-}
sendRaw : (Bool -> msg) -> String -> String -> String -> String -> Cmd msg
sendRaw onSend url apiKey roomId message =
    sendMessage
        (\result ->
            case result of
                Ok () ->
                    onSend True

                Err _ ->
                    onSend False
        )
        (toWebhook url apiKey roomId)
        message


{-| Sometimes the webhook request fails, and you'd like to know why.
The error type explains more about why a request may have failed:

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
    | HomeserverReturnedError Int String
    | HomeserverTimeoutError
    | NetworkError
    | NotJoinedToRoom
    | Unauthorized
    | WebhookMissingInput
    | WebhookReturnedInvalidJSON
    | WebhookTimeoutError


convert : Result Internal.Error () -> Result Error ()
convert result =
    case result of
        Ok () ->
            Ok ()

        Err (Internal.BadUrl url) ->
            Err (BadUrl url)

        Err (Internal.HomeserverReturnedError statusCode errMsg) ->
            Err (HomeserverReturnedError statusCode errMsg)

        Err Internal.HomeserverTimeoutError ->
            Err HomeserverTimeoutError

        Err Internal.NetworkError ->
            Err NetworkError

        Err Internal.NotJoinedToRoom ->
            Err NotJoinedToRoom

        Err Internal.Unauthorized ->
            Err Unauthorized

        Err Internal.WebhookMissingInput ->
            Err WebhookMissingInput

        Err Internal.WebhookReturnedInvalidJSON ->
            Err WebhookReturnedInvalidJSON

        Err Internal.WebhookTimeoutError ->
            Err WebhookTimeoutError
