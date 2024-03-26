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

## Acknowledgments

Thank you to [CodeSandbox](https://github.com/codesandbox/) for updates and maintenance of this library.

## License

Please see [LICENSE](LICENSE) for licensing details.
