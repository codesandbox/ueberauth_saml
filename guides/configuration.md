# Configuration

Below are examples of configuration with several identity providers.
In each case, the Ueberauth provider ID is `[provider]_saml` and the application / service provider ID is `my_app`.
Be sure to change these as appropriate.
Certificates, keys, and metadata XML files are generated or provided separately.

## Google SAML

For Google OAuth integration, see [ueberauth_google](https://hex.pm/packages/ueberauth_google).

```elixir
# config/config.exs

config :ueberauth, Ueberauth,
  providers: [
    google_saml:
      {Ueberauth.Strategy.SAML,
       [
         # Set this to allow sign-in directly from the Google Workspace UI
         allow_idp_initiated_flow: true,

         # Required: All Google SAML responses are POST requests
         callback_methods: ["POST"]
       ]}
  ]
```

```elixir
# config/runtime.exs

config :samly, Samly.Provider,
  service_providers: [
    %{
      # Must match `sp_id` in the identity provider config
      id: "my_app",

      # Must match Entity ID provided to Google
      entity_id: "urn:example.com:production",

      certfile: "/path/to/cert.pem",
      keyfile: "/path/to/key.pem"
    }
  ],
  identity_providers: [
    %{
      # Must match provider ID given in Ueberauth config
      id: "google_saml",

      # Must match `id` from service provider config
      sp_id: "my_app",

      # Google provides this file when creating a SAML app in the Admin UI
      metadata_file: "/path/to/google-idp.xml",

      # Google does not sign assertions, only envelopes.
      signed_assertion_in_resp: false
    }
  ]
```

When configuring the SAML app in the Google Workspace Admin UI, use the following guidance:

* **ACS URL**: Absolute URL to your application's callback route, for example `https://example.com/auth/google_saml/callback`
* **Entity ID**: This should match the `entity_id` given in the service provider configuration above.
* **Signed response**: This value should match the value of `signed_envelopes_in_resp` in the identity provider config.
  It is strongly recommended to use signed responses in a production environment.
* **Certificate**: Ensure the certificate is not expired.
  If you receive a `malformed_certificate` error when logging in, it may be necessary to generate a new certificate.
* **Name ID**: Use `EMAIL` as the format and `Basic Information > Primary email` as the name ID.
* **Attributes**: The following attributes can be mapped and made available through this strategy:
  * **Primary email**: Use `email` to populate the `email` field of the auth struct.
  * **First name**: Use `first_name` to populate the `first_name` field of the auth struct (and the `name` field if `last_name` is also mapped).
  * **Last name**: Use `last_name` to populate the `last_name` field of the auth struct (and the `name` field if `first_name` is also mapped).
  * **Phone number**: Use `phone` to populate the `phone` field of the auth struct.
  * **Address, Locality, etc.**: Use `location` to populate the `location` field of the auth struct.
    Only one field is supported.
  * Additionally, use `birthday`, `description`, `nickname`, and `location` for any other information you would like to appear in the corresponding fields of the auth struct.
