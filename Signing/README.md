# Signing files

Do not commit plaintext private keys, `.p12` files, or Apple certificates.

For the TestFlight workflow place:

- `distribution-private-key.enc` — AES-256 encrypted Apple Distribution private key.
- `autosaleumar-app.mobileprovision` — App Store Connect provisioning profile for `com.autosaleumar.app`.

The encrypted key password belongs in the GitHub secret `IOS_SIGNING_KEY_PASSWORD`.
