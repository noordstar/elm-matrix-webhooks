# Matrix-Webhooks

This library is a wrapper for the [Matrix-Webhook API](https://github.com/nim65s/matrix-webhook) used to send messages to a room. It is a minimalistic way to send messages to a Matrix room using a webhook.

```elm
    import Matrix.Webhooks as MW

    webhook : Webhook
    webhook = 
        MW.toWebhook
            "https://example.com"
            "your-secret-api-key"
            "!abcdef:example.org"
    
    send : String -> Cmd msg
    send = MW.sendMessage toMsg webhook

    -- send "hi mom!"
    -- send "I _support_ **Markdown**!"
    -- send "Pretty cool, _huh?_"
```

## How to install

You can install from the [Elm package list](https://package.elm-lang.org/) using the following command:

```sh
elm install noordstar/elm-matrix-webhooks
```

## Supported versions

The current repository supports the following Matrix-Webhook versions:

- [v3.5.0](https://github.com/nim65s/matrix-webhook/releases/tag/v3.5.0)
- [v3.4.0](https://github.com/nim65s/matrix-webhook/releases/tag/v3.4.0)
- [v3.3.0](https://github.com/nim65s/matrix-webhook/releases/tag/v3.5.0)
- [v3.2.1](https://github.com/nim65s/matrix-webhook/releases/tag/v3.2.1)
- [v3.2.0](https://github.com/nim65s/matrix-webhook/releases/tag/v3.2.0)
- [v3.1.1](https://github.com/nim65s/matrix-webhook/releases/tag/v3.1.1)
- [v3.1.0](https://github.com/nim65s/matrix-webhook/releases/tag/v3.1.0)
- [v3.0.0](https://github.com/nim65s/matrix-webhook/releases/tag/v3.0.0)
- [v2.0.0](https://github.com/nim65s/matrix-webhook/releases/tag/v2.0.0)
- [v1.0.0](https://github.com/nim65s/matrix-webhook/releases/tag/v1.0.0)

The API is designed to be backwards compatible so this list might not be complete: future versions will likely still be compatible.
