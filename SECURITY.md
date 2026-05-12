# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x (current) | ✅ |

---

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

If you discover a security issue — including:
- Authentication bypass
- Cross-user data access
- Exposed API keys or credentials
- Insecure Firestore rules allowing unauthorized reads/writes
- AI prompt injection that bypasses safety checks

Please report it privately:

**Email:** `security@crucue.app`

Include:
1. A description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Any suggested fix (optional)

You will receive an acknowledgment within 48 hours and a resolution timeline within 7 days.

---

## Security model

### Data access
- All Firestore data is scoped to the authenticated user's UID. Cross-user access is not possible through the Firestore security rules.
- Firebase Storage voice audio is only accessible to the owning user during processing. Audio is deleted after successful transcription.

### API keys
- The Gemma 4 API key (`GEMMA4_API_KEY`) is stored in Firebase Secrets Manager. It is never bundled in the Flutter app or any client code.
- Firebase client configuration (project ID, API keys for Firebase services) is embedded in the app — this is standard practice for Firebase client SDKs and is not considered sensitive.

### Responsible disclosure
We follow a coordinated disclosure process. Once a fix is deployed, we will credit reporters in the CHANGELOG (with permission).
