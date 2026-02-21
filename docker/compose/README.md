docker compose up

psql -U myuser -d mydb

List schemas: \dn
List tables in the search path: \dt
Query data: SELECT * FROM bandguy.songs; 

** SSO Users **
http://localhost:8080/
admin admin

** Mail **
http://localhost:8025/#


** ValKey **

Using for Session Management, Room Management, Pub/Sub, SDP blobs, user-user messaging during WebRTC negotiation

** Kong API Gateway ** Note, not using Kong at this point. Keeping for reference:
http://localhost:8001

Step A — Add a downstream service
curl -i -X POST http://localhost:8001/services \
  --data name=api-service \
  --data url=http://host.docker.internal:5000

host.docker.internal allows Kong container to reach your local .NET API.
You can also point it to any downstream microservice.

Step B — Add a route for your service
curl -i -X POST http://localhost:8001/routes \
  --data service.name=api-service \
  --data "paths[]=/api" \
  --data "strip_path=false"

Step C — Enable OIDC / Keycloak plugin
Kong’s OpenID Connect plugin allows SPA login + cookie/session management. Example:
curl -i -X POST http://localhost:8001/services/api-service/plugins \
  --data "name=openid-connect" \
  --data "config.client_id=kong-client" \
  --data "config.client_secret=supersecret" \
  --data "config.discovery=http://host.docker.internal:8080/realms/devrealm/.well-known/openid-configuration" \
  --data "config.scopes=openid,email,profile" \
  --data "config.bearer_only=false" \
  --data "config.session_secret=randomstring123" \
  --data "config.introspection_endpoint=http://host.docker.internal:8080/realms/devrealm/protocol/openid-connect/token/introspect"

discovery points to Keycloak realm metadata
session_secret is used by Kong to encrypt web session cookie
bearer_only=false allows browser-based OIDC login flow
Now web SPA requests can be redirected to Keycloak login automatically.

Step D — Optional: JWT injection for downstream APIs
The plugin can automatically store access token in cookie and inject it as Authorization: Bearer <token> for your proxied requests.
For mobile / API clients, you can send Bearer token in request headers and Kong validates it via OIDC plugin.
3️⃣ SPA Flow with Kong
User clicks Login → hits Kong /api endpoint
Kong sees no session → redirects to Keycloak login
Keycloak authenticates → redirects back to Kong callback endpoint
Kong stores session cookie + access token for this user
SPA calls /api/* → Kong injects Authorization: Bearer <access_token> automatically → downstream API sees JWT
4️⃣ Mobile / PKCE Flow
Mobile app performs PKCE login directly with Keycloak
Receives JWT → sends Authorization: Bearer <token> to Kong API endpoints
Kong validates JWT via OIDC plugin and forwards it downstream
5️⃣ Direct API / Integration Clients
Can use client credentials or pre-issued tokens
Kong validates token via plugin / introspection
Token is injected downstream if needed
✅ Advantages
No YAML required — all dynamic config via Admin API / JSON
Supports multiple client types: SPA, mobile, API
Session / cookie for web, JWT injection downstream automatically
Works well in Docker / local dev environment
Can scale to production easily
