// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
import Bytes
@testable import OAuth2Client

@Suite("ClientAuthMethod (v0.2)")
struct ClientAuthMethodTests {
    @Test(".body (default) includes client_id and client_secret in body (v0.1 regression)")
    func bodyIncludesCredentials() {
        let client = OAuth2Client(
            tokenEndpoint: "https://issuer.example/oauth/token",
            clientID: "myapp",
            clientSecret: "s3cret!"
            // clientAuthMethod defaults to .body
        )
        let body = client.requestBody(grant: .clientCredentials())
        let str = String(decoding: body.storage, as: UTF8.self)
        #expect(str.contains("client_id=myapp"))
        #expect(str.contains("client_secret=s3cret%21"))  // ! → %21
    }

    @Test(".basic excludes client_id and client_secret from body")
    func basicExcludesCredentialsFromBody() {
        let client = OAuth2Client(
            tokenEndpoint: "https://issuer.example/oauth/token",
            clientID: "myapp",
            clientSecret: "s3cret!",
            clientAuthMethod: .basic
        )
        let body = client.requestBody(grant: .clientCredentials())
        let str = String(decoding: body.storage, as: UTF8.self)
        #expect(!str.contains("client_id="))
        #expect(!str.contains("client_secret="))
        #expect(str.contains("grant_type=client_credentials"))
    }

    @Test(".basic + clientSecret returns Authorization: Basic header with RFC 6749 § 2.3.1 encoding")
    func basicAuthHeaderEncoding() {
        let client = OAuth2Client(
            tokenEndpoint: "https://issuer.example/oauth/token",
            clientID: "myapp",
            clientSecret: "s3cret!",
            clientAuthMethod: .basic
        )
        let header = client.basicAuthHeader()
        #expect(header?.name == "Authorization")
        // Per RFC 6749 § 2.3.1:
        //   form-urlencode("myapp")    = "myapp"        (5 bytes)
        //   form-urlencode("s3cret!")  = "s3cret%21"    (9 bytes)
        //   Pair = "myapp:s3cret%21"   (15 bytes)
        //   base64 = "bXlhcHA6czNjcmV0JTIx" (20 chars, no padding since 15 bytes = 5 groups)
        #expect(header?.value == "Basic bXlhcHA6czNjcmV0JTIx")
    }

    @Test(".body returns nil basicAuthHeader")
    func bodyReturnsNilHeader() {
        let client = OAuth2Client(
            tokenEndpoint: "https://issuer.example/oauth/token",
            clientID: "myapp",
            clientSecret: "secret",
            clientAuthMethod: .body
        )
        #expect(client.basicAuthHeader() == nil)
    }

    @Test(".basic + nil clientSecret returns nil basicAuthHeader")
    func basicNilSecretReturnsNil() {
        let client = OAuth2Client(
            tokenEndpoint: "https://issuer.example/oauth/token",
            clientID: "myapp",
            clientSecret: nil,
            clientAuthMethod: .basic
        )
        #expect(client.basicAuthHeader() == nil)
    }
}
