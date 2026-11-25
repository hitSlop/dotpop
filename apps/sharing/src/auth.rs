//! Caller identity verification, independent of room permissions.
//! Accepts either:
//! 1. Self-issued RFC 8037 `EdDSA` (Ed25519) device-keypair JWTs (`sub = "pk:<base64url-32-byte-pubkey>"`)
//!    so any app importing `PopKit` gets zero-config live collaboration without hardcoded app allowlists.
//! 2. Firebase `RS256` ID tokens verified exclusively against Google's fixed certificate endpoint.
#[cfg(target_arch = "wasm32")]
use crate::limits::CERTIFICATE_CACHE_SECONDS;
use crate::limits::{IDENTITY_FIELD_BYTES, IDENTITY_LEEWAY_SECONDS};
use jsonwebtoken::{Algorithm, DecodingKey, Validation, decode, decode_header};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

const TOKEN_BYTES: usize = pop_sharing_protocol::limits::IDENTITY_TOKEN_BYTES;
/// Maximum lifetime for a self-issued `EdDSA` device JWT (15 minutes).
const EDDSA_MAX_TTL_SECONDS: u64 = 900;
/// Base64url-encoded 32-byte Ed25519 public key length without padding (`ceil(32 * 4 / 3) == 43`).
const ED25519_PUB_B64URL_LEN: usize = 43;

#[cfg(target_arch = "wasm32")]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum IdentityError {
    Denied,
    Unavailable,
}
#[derive(Clone, Deserialize)]
pub(crate) struct Claims {
    pub sub: String,
    pub firebase: Firebase,
    pub exp: u64,
    pub iat: u64,
    pub auth_time: u64,
}
#[derive(Clone, Deserialize)]
pub(crate) struct Firebase {
    sign_in_provider: String,
}
#[derive(Clone, Deserialize)]
struct EdDsaClaims {
    sub: String,
    exp: u64,
    iat: u64,
}

pub(crate) fn token_algorithm(token: &str) -> Result<Algorithm, &'static str> {
    if token.len() > TOKEN_BYTES {
        return Err("Invalid identity");
    }
    decode_header(token).map(|h| h.alg).map_err(|_| "Invalid identity")
}

/// Verifies a self-issued `EdDSA` JWT whose `sub` carries `"pk:<base64url-32-byte-ed25519-pubkey>"`.
/// The signature proves possession of the private key matching `sub`; no remote key fetch or
/// hardcoded app allowlist is required.
pub(crate) fn verify_eddsa(token: &str, now: u64) -> Result<VerifiedIdentity, &'static str> {
    if token.len() > TOKEN_BYTES {
        return Err("Invalid identity");
    }
    let header = decode_header(token).map_err(|_| "Invalid identity")?;
    if header.alg != Algorithm::EdDSA {
        return Err("Invalid identity");
    }
    // Extract the claimed public key from the unverified payload before cryptographic verification.
    let mut parts = token.split('.');
    let (_h, payload_b64, _sig, extra) = (parts.next(), parts.next(), parts.next(), parts.next());
    let payload_b64 = payload_b64.filter(|_| extra.is_none()).ok_or("Invalid identity")?;
    let payload_bytes = decode_base64url_nopad(payload_b64).ok_or("Invalid identity")?;
    let unverified: EdDsaClaims = serde_json::from_slice(&payload_bytes).map_err(|_| "Invalid identity")?;
    let pub_b64 = unverified
        .sub
        .strip_prefix("pk:")
        .filter(|pk| pk.len() == ED25519_PUB_B64URL_LEN && decode_base64url_nopad(pk).is_some_and(|b| b.len() == 32))
        .ok_or("Invalid identity")?;

    let key = DecodingKey::from_ed_components(pub_b64).map_err(|_| "Invalid identity")?;
    let mut policy = Validation::new(Algorithm::EdDSA);
    policy.set_required_spec_claims(&["exp", "iat", "sub"]);
    policy.validate_exp = false;
    policy.validate_aud = false;
    policy.leeway = IDENTITY_LEEWAY_SECONDS;
    let claims = decode::<EdDsaClaims>(token, &key, &policy).map_err(|_| "Invalid identity")?.claims;

    if claims.sub != unverified.sub
        || claims.sub.chars().count() > IDENTITY_FIELD_BYTES
        || claims.exp <= claims.iat
        || claims.exp.saturating_sub(claims.iat) > EDDSA_MAX_TTL_SECONDS
        || claims.exp.saturating_add(IDENTITY_LEEWAY_SECONDS) <= now
        || claims.iat > now.saturating_add(IDENTITY_LEEWAY_SECONDS)
    {
        return Err("Invalid identity");
    }
    Ok(VerifiedIdentity { uid: claims.sub, expires: claims.exp })
}

fn decode_base64url_nopad(input: &str) -> Option<Vec<u8>> {
    if input.is_empty() || input.len() % 4 == 1 {
        return None;
    }
    let mut out = Vec::with_capacity((input.len() * 3) / 4);
    let mut buf: u32 = 0;
    let mut bits: u8 = 0;
    for byte in input.bytes() {
        let val: u32 = match byte {
            b'A'..=b'Z' => (byte - b'A') as u32,
            b'a'..=b'z' => (byte - b'a' + 26) as u32,
            b'0'..=b'9' => (byte - b'0' + 52) as u32,
            b'-' => 62,
            b'_' => 63,
            _ => return None,
        };
        buf = (buf << 6) | val;
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            out.push(((buf >> bits) & 0xff) as u8);
        }
    }
    if bits > 0 && (buf & ((1 << bits) - 1)) != 0 {
        return None;
    }
    Some(out)
}
pub(crate) fn key_id(token: &str) -> Result<String, &'static str> {
    if token.len() > TOKEN_BYTES {
        return Err("Invalid identity");
    }
    let header = decode_header(token).map_err(|_| "Invalid identity")?;
    if header.alg != Algorithm::RS256 {
        return Err("Invalid identity");
    }
    header.kid.filter(|id| !id.is_empty() && id.len() <= IDENTITY_FIELD_BYTES).ok_or("Invalid identity")
}
pub(crate) fn verify(token: &str, project: &str, key: &DecodingKey, now: u64) -> Result<Claims, &'static str> {
    key_id(token)?;
    let mut policy = Validation::new(Algorithm::RS256);
    policy.set_audience(&[project]);
    policy.set_issuer(&[format!("https://securetoken.google.com/{project}")]);
    policy.set_required_spec_claims(&["exp", "iss", "aud", "sub", "iat"]);
    // Use the caller's explicit clock for native tests and the same check on Workers.
    policy.validate_exp = false;
    policy.leeway = IDENTITY_LEEWAY_SECONDS;
    let claims = decode::<Claims>(token, key, &policy).map_err(|_| "Invalid identity")?.claims;
    if claims.sub.is_empty()
        || claims.firebase.sign_in_provider == "anonymous"
        || claims.sub.chars().count() > IDENTITY_FIELD_BYTES
        || claims.exp.saturating_add(IDENTITY_LEEWAY_SECONDS) <= now
        || claims.iat > now.saturating_add(IDENTITY_LEEWAY_SECONDS)
        || claims.auth_time > now.saturating_add(IDENTITY_LEEWAY_SECONDS)
        || claims.auth_time > claims.iat
    {
        return Err("Invalid identity");
    }
    Ok(claims)
}

#[derive(Clone, Serialize, Deserialize)]
pub(crate) struct VerifiedIdentity {
    pub uid: String,
    pub expires: u64,
}
impl From<Claims> for VerifiedIdentity {
    fn from(claims: Claims) -> Self {
        Self { uid: claims.sub, expires: claims.exp }
    }
}
#[cfg(target_arch = "wasm32")]
pub(crate) const IDENTITY_HEADER: &str = "X-Pop-Verified-Identity";
#[cfg(target_arch = "wasm32")]
impl VerifiedIdentity {
    pub(crate) fn forward(&self, headers: &mut worker::Headers) -> worker::Result<()> {
        headers.set(IDENTITY_HEADER, &serde_json::to_string(self)?)
    }
    pub(crate) fn from_request(req: &worker::Request) -> worker::Result<Self> {
        let value = req
            .headers()
            .get(IDENTITY_HEADER)?
            .ok_or_else(|| worker::Error::RustError("Missing verified identity".into()))?;
        Ok(serde_json::from_str(&value)?)
    }
}

struct Keys {
    values: BTreeMap<String, DecodingKey>,
    fetched: u64,
    expires: u64,
}
impl Keys {
    /// None requires refresh, Err refuses an unknown ID during the refresh cooldown.
    fn cached(&self, id: &str, now: u64) -> Option<Result<DecodingKey, ()>> {
        if now < self.expires {
            if let Some(key) = self.values.get(id) {
                return Some(Ok(key.clone()));
            }
            if now < self.fetched.saturating_add(30) {
                return Some(Err(()));
            }
        }
        None
    }
}

#[cfg(target_arch = "wasm32")]
mod runtime {
    use super::*;
    use std::cell::RefCell;
    use worker::*;
    type IdentityResult<T> = std::result::Result<T, IdentityError>;
    const CERTIFICATES: &str =
        "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";
    thread_local! { static KEYS: RefCell<Option<Keys>> = const { RefCell::new(None) }; }
    async fn signing_key(id: &str, now: u64) -> IdentityResult<DecodingKey> {
        if let Some(cached) = KEYS.with(|cache| {
            let cache = cache.borrow();
            cache.as_ref()?.cached(id, now)
        }) {
            return cached.map_err(|_| IdentityError::Denied);
        }
        let mut response = Fetch::Url(Url::parse(CERTIFICATES).map_err(|_| IdentityError::Unavailable)?)
            .send()
            .await
            .map_err(|_| IdentityError::Unavailable)?;
        if response.status_code() != 200 {
            return Err(IdentityError::Unavailable);
        }
        let max_age = response
            .headers()
            .get("Cache-Control")
            .map_err(|_| IdentityError::Unavailable)?
            .unwrap_or_default()
            .split(',')
            .find_map(|part| part.trim().strip_prefix("max-age=")?.parse::<u64>().ok())
            .unwrap_or(CERTIFICATE_CACHE_SECONDS)
            .min(86_400);
        let bytes = response.bytes().await.map_err(|_| IdentityError::Unavailable)?;
        if bytes.len() > 256 * 1024 {
            return Err(IdentityError::Unavailable);
        }
        let certificates: BTreeMap<String, String> =
            serde_json::from_slice(&bytes).map_err(|_| IdentityError::Unavailable)?;
        let values: BTreeMap<_, _> = certificates
            .into_iter()
            .map(|(id, pem)| {
                DecodingKey::from_rsa_pem(pem.as_bytes()).map(|key| (id, key)).map_err(|_| IdentityError::Unavailable)
            })
            .collect::<IdentityResult<_>>()?;
        let selected = values.get(id).cloned();
        KEYS.with(|cache| {
            *cache.borrow_mut() = Some(Keys { values, fetched: now, expires: now.saturating_add(max_age) })
        });
        selected.ok_or(IdentityError::Denied)
    }
    pub(crate) async fn identity(req: &Request, env: &Env) -> IdentityResult<VerifiedIdentity> {
        let header = req.headers().get("Authorization").map_err(|_| IdentityError::Denied)?.unwrap_or_default();
        let token = header.strip_prefix("Bearer ").ok_or(IdentityError::Denied)?;
        let now = (js_sys::Date::now() / 1000.) as u64;
        match token_algorithm(token).map_err(|_| IdentityError::Denied)? {
            Algorithm::EdDSA => verify_eddsa(token, now).map_err(|_| IdentityError::Denied),
            Algorithm::RS256 => {
                let id = key_id(token).map_err(|_| IdentityError::Denied)?;
                let project = env.var("FIREBASE_PROJECT").map_err(|_| IdentityError::Unavailable)?.to_string();
                let key = signing_key(&id, now).await?;
                verify(token, &project, &key, now).map(VerifiedIdentity::from).map_err(|_| IdentityError::Denied)
            }
            _ => Err(IdentityError::Denied),
        }
    }
}
#[cfg(target_arch = "wasm32")]
pub(crate) use runtime::identity;

#[cfg(test)]
mod tests {
    use super::*;
    use jsonwebtoken::{EncodingKey, Header, encode};
    use rand::SeedableRng;
    use rsa::pkcs1::{EncodeRsaPrivateKey, EncodeRsaPublicKey};
    use serde_json::{Value, json};
    use std::sync::OnceLock;
    const NOW: u64 = 1_700_000_000;
    fn keys() -> &'static (EncodingKey, DecodingKey) {
        static KEYS: OnceLock<(EncodingKey, DecodingKey)> = OnceLock::new();
        KEYS.get_or_init(|| {
            // Deterministic test-only identity; no saved private keys or Firebase users.
            let mut rng = rand::rngs::StdRng::seed_from_u64(753);
            let key = rsa::RsaPrivateKey::new(&mut rng, 2048).unwrap();
            (
                EncodingKey::from_rsa_der(key.to_pkcs1_der().unwrap().as_bytes()),
                DecodingKey::from_rsa_der(key.to_public_key().to_pkcs1_der().unwrap().as_bytes()),
            )
        })
    }
    fn claims() -> Value {
        json!({"sub":"test-user","aud":"hitslopapp","iss":"https://securetoken.google.com/hitslopapp",
            "firebase":{"sign_in_provider":"apple.com"},"exp":NOW+3600,"iat":NOW,"auth_time":NOW-10})
    }
    fn token(claims: &Value, kid: &str) -> String {
        let mut header = Header::new(Algorithm::RS256);
        header.kid = Some(kid.into());
        encode(&header, claims, &keys().0).unwrap()
    }
    #[test]
    fn firebase_identity_accepts_small_clock_skew() {
        let mut changed = claims();
        changed["iat"] = json!(NOW + 60);
        changed["auth_time"] = json!(NOW + 60);
        assert!(verify(&token(&changed, "current"), "hitslopapp", &keys().1, NOW).is_ok());
        changed = claims();
        changed["exp"] = json!(NOW - 59);
        assert!(verify(&token(&changed, "current"), "hitslopapp", &keys().1, NOW).is_ok());
    }
    #[test]
    fn firebase_identity_requires_signature_project_times_and_nonempty_subject() {
        let signed = token(&claims(), "current");
        assert_eq!(key_id(&signed).unwrap(), "current");
        assert_eq!(verify(&signed, "hitslopapp", &keys().1, NOW).unwrap().sub, "test-user");
        assert!(verify(&signed, "another-project", &keys().1, NOW).is_err());
        assert!(verify(&signed, "hitslopapp", &keys().1, NOW + 3660).is_err());
        for (field, value) in [
            ("sub", json!("")),
            ("sub", json!("x".repeat(129))),
            ("aud", json!("other")),
            ("iss", json!("https://attacker.example")),
            ("iat", json!(NOW + 61)),
            ("auth_time", json!(NOW + 61)),
            ("auth_time", json!("invalid")),
            ("exp", json!(NOW - 60)),
        ] {
            let mut changed = claims();
            changed[field] = value;
            assert!(verify(&token(&changed, "current"), "hitslopapp", &keys().1, NOW).is_err(), "{field}");
        }
        for field in ["sub", "aud", "iss", "exp", "iat", "auth_time"] {
            let mut changed = claims();
            changed.as_object_mut().unwrap().remove(field);
            assert!(verify(&token(&changed, "current"), "hitslopapp", &keys().1, NOW).is_err(), "{field}");
        }
        let mut forged: Vec<_> = signed.split('.').map(str::to_owned).collect();
        // Replace only the payload of a genuinely signed token.
        let mut changed = claims();
        changed["sub"] = json!("other-user");
        forged[1] = token(&changed, "current").split('.').nth(1).unwrap().into();
        assert!(verify(&forged.join("."), "hitslopapp", &keys().1, NOW).is_err());
    }
    #[test]
    fn verified_identity_requires_named_sign_in_and_carries_expiry() {
        for provider in ["apple.com", "google.com", "password"] {
            let mut changed = claims();
            changed["firebase"]["sign_in_provider"] = json!(provider);
            let identity =
                VerifiedIdentity::from(verify(&token(&changed, "current"), "hitslopapp", &keys().1, NOW).unwrap());
            assert_eq!(identity.uid, "test-user");
            assert_eq!(identity.expires, NOW + 3600);
        }
        let mut changed = claims();
        changed["firebase"]["sign_in_provider"] = json!("anonymous");
        assert!(verify(&token(&changed, "current"), "hitslopapp", &keys().1, NOW).is_err());
        let mut changed = claims();
        changed.as_object_mut().unwrap().remove("firebase");
        assert!(verify(&token(&changed, "current"), "hitslopapp", &keys().1, NOW).is_err());
    }
    #[test]
    fn firebase_identity_refuses_algorithm_confusion_and_missing_key_ids() {
        let hmac = encode(&Header::new(Algorithm::HS256), &claims(), &EncodingKey::from_secret(b"test")).unwrap();
        assert!(key_id(&hmac).is_err());
        assert!(verify(&hmac, "hitslopapp", &keys().1, NOW).is_err());
        assert!(key_id(&token(&claims(), "")).is_err());
        assert!(key_id(&"x".repeat(TOKEN_BYTES + 1)).is_err());
        assert!(key_id("malformed").is_err());
    }
    #[test]
    fn firebase_keys_refresh_on_rotation_and_expiry_without_unknown_id_fetch_storms() {
        let current =
            Keys { values: BTreeMap::from([("current".into(), keys().1.clone())]), fetched: NOW, expires: NOW + 3600 };
        assert!(current.cached("current", NOW).unwrap().is_ok());
        assert!(current.cached("rotated", NOW + 29).unwrap().is_err());
        assert!(current.cached("rotated", NOW + 30).is_none());
        assert!(current.cached("current", NOW + 3600).is_none());
        // A successful refresh replaces, rather than extends, the trusted key set.
        let refreshed = Keys {
            values: BTreeMap::from([("rotated".into(), keys().1.clone())]),
            fetched: NOW + 30,
            expires: NOW + 3630,
        };
        let signed = token(&claims(), "rotated");
        assert!(
            verify(&signed, "hitslopapp", &refreshed.cached("rotated", NOW + 30).unwrap().unwrap(), NOW + 30).is_ok()
        );
        assert!(refreshed.cached("current", NOW + 30).unwrap().is_err());
    }

    #[test]
    fn eddsa_device_identity_verifies_valid_tokens_and_rejects_forgeries() {
        // RFC 8410 Section 10.3 test vector (Ed25519 PKCS#8 v1 private key + matching 32-byte public key).
        let pkcs8_der: [u8; 48] = [
            0x30, 0x2e, 0x02, 0x01, 0x00, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x04, 0x22, 0x04, 0x20,
            0xd4, 0xee, 0x72, 0xdb, 0xf9, 0x13, 0x58, 0x4a, 0xd5, 0xb6, 0xd8, 0xf1, 0xf7, 0x69, 0xf8, 0xad,
            0x3a, 0xfe, 0x7c, 0x28, 0xcb, 0xf1, 0xd4, 0xfb, 0xe0, 0x97, 0xa8, 0x8f, 0x44, 0x75, 0x58, 0x42,
        ];
        // Matching Ed25519 public key for the RFC 8410 seed above:
        // 19bf44096984cdfe8541bac167dc3b96c85086aa30b6b6cb0c5c38ad703166e1
        let pub_b64 = "Gb9ECWmEzf6FQbrBZ9w7lshQhqowtrbLDFw4rXAxZuE";
        let sub = format!("pk:{pub_b64}");
        let enc = EncodingKey::from_ed_der(&pkcs8_der);

        let valid_claims = json!({ "sub": sub, "iat": NOW, "exp": NOW + 600 });
        let jwt = encode(&Header::new(Algorithm::EdDSA), &valid_claims, &enc).unwrap();
        assert_eq!(token_algorithm(&jwt).unwrap(), Algorithm::EdDSA);
        let id = verify_eddsa(&jwt, NOW).unwrap();
        assert_eq!(id.uid, format!("pk:{pub_b64}"));
        assert_eq!(id.expires, NOW + 600);

        // Expired token rejected
        assert!(verify_eddsa(&jwt, NOW + 661).is_err());

        // Overlong TTL (> 900s) rejected
        let long_ttl = encode(&Header::new(Algorithm::EdDSA), &json!({ "sub": sub, "iat": NOW, "exp": NOW + 901 }), &enc).unwrap();
        assert!(verify_eddsa(&long_ttl, NOW).is_err());

        // Tampered subject rejected (signature mismatch)
        let mut parts: Vec<_> = jwt.split('.').map(str::to_owned).collect();
        let other = encode(
            &Header::new(Algorithm::EdDSA),
            &json!({ "sub": "pk:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "iat": NOW, "exp": NOW + 600 }),
            &enc,
        ).unwrap();
        parts[1] = other.split('.').nth(1).unwrap().into();
        assert!(verify_eddsa(&parts.join("."), NOW).is_err());

        // Non-pk subject rejected
        let non_pk = encode(&Header::new(Algorithm::EdDSA), &json!({ "sub": "user-123", "iat": NOW, "exp": NOW + 600 }), &enc).unwrap();
        assert!(verify_eddsa(&non_pk, NOW).is_err());
    }
}
