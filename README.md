# Ueberauth SAML

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

Ueberauth plugin for SAML-based identity providers

## What is this?

[Ueberauth](https://github.com/ueberauth/ueberauth) is an authentication framework for Elixir applications that specializes in [OAuth](https://oauth.net/).
This library is one of many [plugins](https://github.com/ueberauth/ueberauth/wiki/List-of-Strategies) (called Strategies) that allow Ueberauth to integrate with different identity providers.
Specifically, this one adapts Ueberauth to integrate with SAML-based identity providers.
SAML is a separate protocol from OAuth that can also be used for single sign-on applications.

## Installation

This application is not currently available on `Hex.pm`.
In the meantime, install it directly from GitHub:

```elixir
def deps do
  [
    {:ueberauth_saml, github: "codesandbox/ueberauth_saml"}
  ]
end
```

## Configuration

This strategy uses [Samly](https://hex.pm/package/samly) and its sub-dependency [esaml](https://hex.pm/package/esaml) to interact with SAML Identity Providers.
As a result, using this strategy requires two sets of configuration.

### Strategy Configuration

First, configure this strategy as an Ueberauth provider.
This configuration should occur **at compile time**:

```elixir
# config/config.exs

config :ueberauth, Ueberauth,
  providers: [
    # ...
    saml:
      {Ueberauth.Strategy.SAML,
       [
         allow_idp_initiated_flow: true,
         callback_methods: ["POST"]
       ]}
  ]
```

Here, the `saml` key is the provider ID that will be used in routes (for example `/auth/saml`).
This provider ID **must** match an identity provider ID used in the next configuration block.

Below are the available configuration keys that can be passed directly to the strategy:

| Key | Type | Description |
| --- | ---- | ----------- |
| `allow_idp_initiated_flow` | boolean | Whether to allow logins that start from the Identity Provider (ex. Google app sheet or Okta tile). Defaults to `false`. |
| `callback_methods` | List of HTTP verbs | HTTP methods used by the Identity Provider to complete a login. Many providers require `["POST"]`. Defaults to `["GET"]`. |

## Samly Configuration

Second, configure the Samly library.
This requires configuring the service provider (your app) and identity provider(s) (like Google, Okta, etc.).
Runtime configuration is often appropriate for this:

```elixir
# config/runtime.exs

config :samly, Samly.Provider,
  service_providers: [
    %{
      id: "my_app",
      entity_id: "urn:example.com:production",
      certfile: "/path/to/cert.pem",
      keyfile: "/path/to/key.pem",
      contact_name: "My Company Support",
      contact_email: "support@example.com",
      org_name: "My Company",
      org_displayname: "My Co.",
      org_url: "https://example.com"
    }
  ],
  identity_providers: [
    %{
      id: "google_saml",
      sp_id: "my_app",
      base_url: "https://example.com/",
      metadata_file: "/path/to/idp-metadata.xml",
      sign_requests: true,
      sign_metadata: true,
      signed_assertion_in_resp: false,
      signed_envelopes_in_resp: false
    }
  ]
```

Remember that the identity provider `id` must match the provider ID given to Ueberauth.
Meanwhile, the `sp_id` given to the identity provider should match the `id` of a service provider above.

Note that not all Samly configuration is useful with this strategy.
The following keys are used:

#### Service Provider

At least one service provider must be configured.

| Key | Type | Example | Description |
| --- | ---- | ------- | ----------- |
| `id` | string | `"my_app"` | **Required**. Identifier for your application. |
| `entity_id` | string | `"urn:example.com:production"` | **Required**. Unique identifier for your application across all service providers configured with your identity provider. Must match the entity provider configured with your identity provider. |
| `certfile` | file path | `"/path/to/cert.pem"` | Path to a PEM-formatted certificate that will be used to sign data from your application to the identity provider. Setting this is **strongly recommended** for production deployments. If unset, ensure the identity provider is configured with `sign_requests: false`. |
| `keyfile` | file path | `"/path/to/key.pem"` | Path to a PEM-formatted private key that will be used to sign data form your application to the identity provider. Setting this is **strongly recommended** for production deployments. If unset, ensure the identity provider is configured with `sign_requests: false`. |
| `contact_name` | string | `My Company Support` | Optional technical contact name for your application. |
| `contact_email` | string | `support@example.com` | Optional technical contact email for your application. |
| `org_name` | string | `My Company` | Optional name of your application's organization. |
| `org_displayname` | string | `My Co.` | Optional display name of your application's organization. |
| `org_url` | string | `My Co.` | Optional web URL of your application's organization. |

#### Identity Provider

One identity provider should be configured for each Ueberauth provider (with the same `id`).

| Key | Type | Example | Description |
| --- | ---- | ------- | ----------- |
| `id` | string | `"google_saml"` | **Required**. Identifier for the identity provider. Must match the name of the corresponding provider configured with Ueberauth. |
| `sp_id` | string | `"my_app"` | **Required**. Identifier for your application / the service provider to use with this identity provider. Must match an `id` given to a service provider above. |
| `metadata_file` | file path | `"/path/to/idp-metadata.xml"` | **Required** if `metadata` is not set. Path to an XML file provided by your identity provider with information about the provider. |
| `metadata` | string | XML contents | **Required** if `metadata_file` is not set. Inline XML contents provided by your identity provider with information about the provider. |
| `sign_requests` | boolean | `true` | Whether to sign requests sent from your application to the identity provider. This may be required by your identity provider, and is strongly recommended for production deployments. Must be `false` if a `certfile` and `keyfile` are not provided in the corresponding service provider. Defaults to `true`. |
| `signed_assertion_in_resp` | boolean | `true` | Whether your application should expect the identity provider to sign assertions in its responses. Identity providers may sign the envelope without signing the assertion. Defaults to `true`. |
| `signed_envelopes_in_resp` | boolean | `true` | Whether your application should expect the identity provider to sign the envelopes of its responses. Identity providers may sign the envelope without signing the assertion. Defaults to `true`. |


## Acknowledgments

Thank you to [CodeSandbox](https://github.com/codesandbox/) for updates and maintenance of this library.

## License

Please see [LICENSE](LICENSE) for licensing details.
