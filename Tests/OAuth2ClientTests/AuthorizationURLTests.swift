// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OAuth2Client

@Suite("Authorization URL builder (v0.2)")
struct AuthorizationURLTests {
    private static let client = OAuth2Client(
        tokenEndpoint: "https://issuer.example/oauth/token",
        clientID: "myapp"
    )

    @Test("minimal: response_type + client_id + redirect_uri")
    func minimal() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb"
        )
        #expect(url.hasPrefix("https://issuer.example/oauth/authorize?"))
        #expect(url.contains("response_type=code"))
        #expect(url.contains("client_id=myapp"))
        #expect(url.contains("redirect_uri=https%3A%2F%2Fapp.example%2Fcb"))
    }

    @Test("scope parameter is included when set")
    func withScope() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb",
            scope: "openid profile"
        )
        // Spaces in form-urlencoded → '+'
        #expect(url.contains("scope=openid+profile"))
    }

    @Test("state parameter is included when set")
    func withState() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb",
            state: "xyz123"
        )
        #expect(url.contains("state=xyz123"))
    }

    @Test("nonce parameter is included when set")
    func withNonce() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb",
            nonce: "n-0S6_WzA2Mj"
        )
        #expect(url.contains("nonce=n-0S6_WzA2Mj"))
    }

    @Test("code_challenge + code_challenge_method when set")
    func withPKCE() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb",
            codeChallenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
            codeChallengeMethod: .s256
        )
        #expect(url.contains("code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"))
        #expect(url.contains("code_challenge_method=S256"))
    }

    @Test("all standard params together")
    func everything() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb",
            scope: "openid",
            state: "s",
            nonce: "n",
            codeChallenge: "c",
            codeChallengeMethod: .s256
        )
        #expect(url.contains("response_type=code"))
        #expect(url.contains("scope=openid"))
        #expect(url.contains("state=s"))
        #expect(url.contains("nonce=n"))
        #expect(url.contains("code_challenge=c"))
        #expect(url.contains("code_challenge_method=S256"))
    }

    @Test("additionalParams are appended")
    func additional() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb",
            additionalParams: [("prompt", "consent"), ("login_hint", "user@example.com")]
        )
        #expect(url.contains("prompt=consent"))
        // '@' is form-urlencoded as %40
        #expect(url.contains("login_hint=user%40example.com"))
    }

    @Test("custom responseType (e.g., hybrid 'code id_token')")
    func customResponseType() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb",
            responseType: "code id_token"
        )
        // Space in 'code id_token' → '+'
        #expect(url.contains("response_type=code+id_token"))
    }

    @Test("special characters in redirectURI are form-urlencoded")
    func redirectURIEncoding() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb?foo=bar&baz=qux"
        )
        // : / ? = & all need encoding.
        #expect(url.contains("redirect_uri=https%3A%2F%2Fapp.example%2Fcb%3Ffoo%3Dbar%26baz%3Dqux"))
    }

    @Test("authorizationEndpoint is prefix; '?' separator follows")
    func endpointPrefix() {
        let url = Self.client.authorizationURL(
            authorizationEndpoint: "https://issuer.example/oauth/authorize",
            redirectURI: "https://app.example/cb"
        )
        let questionIndex = url.firstIndex(of: "?")
        #expect(questionIndex != nil)
        let prefix = String(url[..<(questionIndex ?? url.startIndex)])
        #expect(prefix == "https://issuer.example/oauth/authorize")
    }
}
