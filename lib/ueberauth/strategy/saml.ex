defmodule Ueberauth.Strategy.SAML do
  use Ueberauth.Strategy,
    allow_ipd_initiated_flow: true,
    ignores_csrf_attack: true

  require UeberauthSAML

  alias Plug.Conn
  alias Samly.Assertion
  alias Samly.IdpData

  @name_format_email ~c"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
  @private_key_assertion :ueberauth_saml_assertion
  @session_key_state :ueberauth_saml_state

  #
  # Request Phase
  #

  @impl true
  def handle_request!(conn) do
    maybe_refresh_providers()
    provider = strategy_name(conn) |> to_string()

    %IdpData{
      esaml_idp_rec: idp_rec,
      esaml_sp_rec: sp_rec
    } = Samly.Helper.get_idp(provider)

    sp = put_uris(conn, sp_rec)
    relay_state = :crypto.strong_rand_bytes(24) |> Base.url_encode64()
    idp_signin_url = UeberauthSAML.esaml_idp_metadata(idp_rec, :login_location)

    xml_fragment =
      :esaml_sp.generate_authn_request(idp_signin_url, sp, @name_format_email) |> IO.inspect()

    redirect_url =
      :esaml_binding.encode_http_redirect(
        idp_signin_url,
        xml_fragment,
        :undefined,
        relay_state
      )

    conn
    |> Conn.configure_session(renew: true)
    |> Conn.put_session(@session_key_state, relay_state)
    |> redirect!(redirect_url)
  end

  #
  # Callback Phase
  #

  @impl true
  def handle_callback!(conn) do
    maybe_refresh_providers()
    provider = strategy_name(conn) |> to_string()
    %IdpData{esaml_sp_rec: sp_rec} = Samly.Helper.get_idp(provider)

    sp = put_uris(conn, sp_rec)
    saml_encoding = conn.body_params["SAMLEncoding"]
    saml_response = conn.body_params["SAMLResponse"]
    relay_state = conn.body_params["RelayState"] |> safe_decode_www_form()

    with {:ok, assertion} <- decode_idp_response(conn, sp, saml_encoding, saml_response),
         :ok <- validate_state(conn, assertion, relay_state) do
      Conn.put_private(conn, @private_key_assertion, assertion)
      |> IO.inspect()
    end
  end

  @spec put_uris(Conn.t(), :esaml.sp()) :: :esaml.sp()
  defp put_uris(conn, sp_rec) do
    request_url = request_url(conn)
    callback_url = callback_url(conn)

    UeberauthSAML.esaml_sp(
      sp_rec,
      metadata_uri: String.to_charlist(Path.join(request_url, "metadata")),
      consume_uri: String.to_charlist(callback_url)
    )
  end

  @spec safe_decode_www_form(String.t() | nil) :: binary
  defp safe_decode_www_form(nil), do: ""
  defp safe_decode_www_form(data), do: URI.decode_www_form(data)

  @spec decode_idp_response(Conn.t(), :esaml.sp(), String.t(), String.t()) ::
          {:ok, Assertion.t()} | Conn.t()
  defp decode_idp_response(conn, sp, saml_encoding, saml_response) do
    xml_fragment = :esaml_binding.decode_response(saml_encoding, saml_response)

    case :esaml_sp.validate_assertion(xml_fragment, sp) do
      {:ok, assertion_rec} -> {:ok, Assertion.from_rec(assertion_rec)}
      {:error, reason} -> set_errors!(conn, [error("invalid_response", inspect(reason))])
    end
  rescue
    error -> set_errors!(conn, [error("invalid_response", inspect(error))])
  end

  @spec validate_state(Conn.t(), Assertion.t(), binary) :: :ok | {:error, atom}
  defp validate_state(conn, assertion, relay_state)

  # IDP-initiated flow
  defp validate_state(conn, %{subject: %{in_response_to: ""}}, relay_state) do
    if option(conn, :allow_idp_initiated_flow) do
      if allowed_target_urls = option(conn, :allowed_target_urls) do
        if relay_state in allowed_target_urls do
          :ok
        else
          set_errors!(conn, [error("invalid_target", "Invalid target URL")])
        end
      else
        :ok
      end
    else
      set_errors!(conn, [
        error("invalid_flow", "Identity Provider-initiated logins are not allowed")
      ])
    end
  end

  # SP-initiated flow
  defp validate_state(conn, _assertion, relay_state) do
    rs_in_session = Conn.get_session(conn, @session_key_state)

    cond do
      rs_in_session == nil || rs_in_session != relay_state ->
        set_errors!(conn, [error("invalid_state", "Invalid target URL")])

      true ->
        :ok
    end
  end

  #
  # Post-callback cleanup
  #

  @impl true
  def handle_cleanup!(conn) do
    put_private(conn, @private_key_assertion, nil)
  end

  #
  # Response Decoding
  #

  @impl true
  def extra(conn) do
    %Samly.Assertion{attributes: attributes} = conn.private[@private_key_assertion]
    %Ueberauth.Auth.Extra{raw_info: attributes}
  end

  @impl true
  def info(conn) do
    %Samly.Assertion{attributes: attributes} = assertion = conn.private[@private_key_assertion]

    %Ueberauth.Auth.Info{
      birthday: attributes["birthday"],
      description: attributes["description"],
      email: extract_email(assertion),
      first_name: attributes["first_name"],
      image: attributes["image"],
      last_name: attributes["last_name"],
      location: attributes["location"],
      name: extract_name(attributes),
      nickname: attributes["nickname"],
      phone: attributes["phone"]
    }
  end

  @impl true
  def uid(conn) do
    %Samly.Assertion{subject: %Samly.Subject{name: name}} = conn.private[@private_key_assertion]
    name
  end

  @spec extract_email(Samly.Assertion.t()) :: String.t() | nil
  defp extract_email(%{attributes: %{"email" => email}}), do: email

  defp extract_email(%{
         subject: %{
           name_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
           name: email
         }
       }) do
    email
  end

  defp extract_email(_assertion), do: nil

  @spec extract_name(map) :: String.t()
  defp extract_name(%{"first_name" => first_name, "last_name" => last_name}) do
    <<first_name::binary, " ", last_name::binary>>
  end

  defp extract_name(%{"name" => name}), do: name
  defp extract_name(_attributes), do: "Unknown"

  #
  # Configuration
  #

  @spec maybe_refresh_providers :: :ok
  defp maybe_refresh_providers do
    if :persistent_term.get(:ueberauth_saml_providers_loaded?, false) do
      :ok
    else
      Samly.Provider.refresh_providers()
      :persistent_term.put(:ueberauth_saml_providers_loaded?, true)
    end
  end

  @spec option(Conn.t(), atom) :: atom
  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
