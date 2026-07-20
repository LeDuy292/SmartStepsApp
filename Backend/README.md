# SmartStepsServer
Source code server for SmartSteps application.

## Local setup

Requirements:

- .NET 8 SDK or newer
- PostgreSQL 14 or newer, or a reachable PostgreSQL-compatible database

Create the local environment file from the committed template and replace the
placeholder database/JWT values:

```powershell
Copy-Item .env.example .env
dotnet tool restore
dotnet restore
dotnet build --no-restore
dotnet run --no-build
```

The API listens on `http://localhost:8080` by default. Verify it with:

```powershell
Invoke-WebRequest http://localhost:8080/health -UseBasicParsing
```

Pending EF Core migrations are applied automatically after PostgreSQL becomes
reachable. Swagger is available at `/swagger` in Development or when
`Swagger__Enabled=true`.

Google login needs `GoogleAuth__ClientId`. Password-recovery email needs all
`EmailSettings__*` values. Cloudinary, payOS and DeepSeek are optional for
basic local startup; do not commit their credentials to `appsettings.json`.

To inspect or apply migrations manually:

```powershell
dotnet ef migrations list
dotnet ef database update
```

## Seeded situation content

The SmartSteps lesson catalog is configured in `SmartStepsDbContext` with EF
Core `HasData`. The generated migration creates 3 islands and 9 published
situations from the SmartSteps content document, including steps, flashcards,
skills, and parent review notes. Startup does not run a custom seeder.

Published lessons are exposed to the app through:

```http
GET /api/situations
GET /api/situations/{id}
```

## Learning progress and parent reports

The backend records resumable progress and evaluates answers on the server so
the mobile app cannot change the configured correct answer.

```http
POST /api/progress/start
PUT  /api/progress/step
POST /api/progress/answer
POST /api/progress/complete
```

Generate a 30-day report after the child has completed at least one lesson:

```http
POST /api/learning-analysis/{childId}/reports
Content-Type: application/json

{}
```

Custom periods use UTC timestamps in `periodFrom` and `periodTo`. The rule
engine calculates completion, accuracy, skill mastery and recommendations
before any narrative is produced. Only published situations can be
recommended.

```http
GET  /api/learning-analysis/{childId}/reports/latest
GET  /api/learning-analysis/{childId}/recommendations
POST /api/learning-analysis/{childId}/recommendations/{situationId}/review
PATCH /api/learning-analysis/{childId}/recommendations/{recommendationId}
```

The current local implementation uses an approved rule-based Vietnamese
narrative and records `RuleBasedFallback` in `AIAnalysisLog`. This keeps reports
available without sending personal or raw learning history to an external AI
provider. A provider-specific narrative generator can be added behind
`ILearningAnalysisService` once its endpoint, model and credentials are chosen.

## Private Cloudinary media

Use the backend to create short-lived signed URLs for private Cloudinary media. Do not put the Cloudinary API secret in the mobile app.

Set these values on the server through environment variables:

```powershell
$env:Cloudinary__CloudName="your-cloud-name"
$env:Cloudinary__ApiKey="your-api-key"
$env:Cloudinary__ApiSecret="your-api-secret"
$env:Cloudinary__SignedUrlExpiresInSeconds="300"
```

The server signs Cloudinary download URLs for published lesson videos and voice clips. The frontend does not need to call Cloudinary directly.

```http
POST /api/media/signed-url
Content-Type: application/json

{
  "stepId": 1
}
```

The endpoint only signs media from a published `SituationStep`. Store `SituationStep.MediaUrl` as either the Cloudinary public ID path, for example `Safety_smallitems_intro_cw1tlh.mp4`, or a Cloudinary delivery URL for the configured cloud.

## Premium subscriptions and payOS

Premium access is stored on the server in `PremiumSubscription`. Expired
subscriptions are marked as `Expired` whenever premium status is requested, so
locked lessons automatically become locked again after the subscription end
date.

Apply the premium schema migration:

```powershell
dotnet ef database update --project SmartStepsServer/SmartStepsServer.csproj --startup-project SmartStepsServer/SmartStepsServer.csproj
```

Configure payOS from the payment channel on `https://my.payos.vn`:

```powershell
$env:PayOS__ClientId="your-payos-client-id"
$env:PayOS__ApiKey="your-payos-api-key"
$env:PayOS__ChecksumKey="your-payos-checksum-key"
$env:PayOS__ReturnUrl="http://localhost:3000/learning?premiumPayment=success"
$env:PayOS__CancelUrl="http://localhost:3000/learning?premiumPayment=cancel"
```

For production, set the webhook URL in payOS to:

```http
https://your-domain.com/api/premium/payos/webhook
```

For local webhook testing, expose the API through a tunnel such as ngrok and use
the tunnel URL. You can also confirm the webhook URL through the backend:

```http
POST /api/premium/payos/confirm-webhook
Content-Type: application/json

{
  "webhookUrl": "https://your-domain.com/api/premium/payos/webhook"
}
```

The MVP test code is `PREMIUM`. It activates one month of premium access and can
only be redeemed once per account email.
