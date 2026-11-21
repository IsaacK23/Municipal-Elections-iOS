# iOS Assignment 2 Plan — Municipal Elections Companion

**Due:** Fri Nov 20, 2026, 11:59 pm (same day as COMP4976 A2) · **Team:** Isaac Kehler, Cali Heung
**Backend:** `COMP4976-Assignment-2` → `MEMS.Api` (the new Aspire solution), **not** the A1 MVC app.

---

## Phase 0 — Backend decision: how the iOS app reaches the API

> **Revised (Nov 20): use the A1 API, not the 4976 A2 API.** The iOS spec says "The ASP.NET Core Web API
> from Assignment #1 will continue to be used" and "Students must use their existing ASP.NET Core Web API".
> The A1 API already runs on SQLite on Azure, which matches the instructor's advice. It was updated in
> `Municipal-Elections-Management-System` (branch `ios-a2-municipality-filter`, merged to `main`, which
> auto-deploys):
> - `municipalityId` is required on `/api/candidates`, `/api/candidates/search` and `/api/positions`
>   (400 if missing, 404 if unknown)
> - get-by-id is scoped to the municipality
> - `/api/savedcandidates` is removed (selections move to Firestore)
>
> The `a1-submission` tag marks the graded A1 state. Nothing changes in `COMP4976-Assignment-2`.
> The analysis below is kept for reference; D0 and sections 0.1–0.3 no longer apply. Firestore stores
> `municipalityId` + `municipalityName` instead of a slug (D3).

### The problem

| Constraint | Source |
|---|---|
| COMP4976 A2 must use SQL Server; "SQLite is not permitted"; no Azure deployment | 4976 spec §4 |
| The iOS app needs a deployed API it can reach | 4977 spec, Deliverables → "Azure API URL" |
| Azure SQL costs too many credits; use SQLite **for the deployed API only** | Instructor (screenshot) |
| Deploy **only the API** | Instructor (screenshot) |
| Submit "Updated ASP.NET Core Web API source code" | 4977 spec, Deliverables |

### Options

| Option | Verdict |
|---|---|
| **A. Copy the whole .NET solution and change the copy to SQLite** | ✗ Every API change the iOS app needs (register, voter role, `/me`, search fix) would have to be made twice. The two copies drift apart, and it's unclear which one is the "updated API source code". |
| **B. One codebase. The database provider is a config setting: SQL Server by default (Aspire), SQLite when deployed to Azure** | ✓ **Recommended.** About 30 lines of change. The 4976 submission still runs on SQL Server through Aspire, and the 4977 deployment uses the same API code. |
| C. Deploy to Azure with Azure SQL | ✗ The instructor ruled it out because of cost. |
| D. Deploy the A1 MVC app again | ✗ It has the old routes and the `SavedCandidates` API. 4977 A2 assumes the API from A1 *with* municipality filtering, and the new API already has that (`/api/{tenant}/...`). |

### Decision D0: Option B, deploy `MEMS.Api` alone, `Database:Provider = Sqlite`

Why this is enough: the new API already stores images in the database (`StoredImage`), so you don't need a
disk uploads folder. It already scopes data by tenant through the route (`/api/burnaby/candidates`), which
meets the iOS spec's "route parameters" option. A2 also removes the SavedCandidates endpoints (4976 D9), and
the iOS spec moves selections to Firebase, so the two specs agree on that.

#### 0.1 Make the API provider-switchable (in `COMP4976-Assignment-2`, branch `ios-azure-sqlite` → PR to `main`)

- [ ] `Directory.Packages.props`: add `Microsoft.EntityFrameworkCore.Sqlite`; reference it from `MEMS.Api`.
- [ ] `MEMS.Api/Program.cs`: read `Database:Provider` (default `SqlServer`):
  - `SqlServer` → current code (`UseSqlServer` + `EnrichSqlServerDbContext`).
  - `Sqlite` → `UseSqlite(ConnectionStrings:memsdb)`, skip the Aspire SQL Server enrichment.
- [ ] `SeedData.InitializeAsync`: `db.Database.IsSqlServer() ? MigrateAsync() : EnsureCreatedAsync()`.
  The existing migrations are SQL Server-specific. `EnsureCreated` builds the SQLite schema from the model, so you
  don't need a second set of migrations.
- [ ] `AppDbContext`: add `CK_Municipalities_Slug` only when `Database.IsSqlServer()`. It uses T-SQL
  (`COLLATE Latin1_General_BIN2`, `[^a-z0-9-]`), which SQLite rejects. `CK_Positions_SeatsAvailable` works on both.
- [ ] `CandidateService` name search: `Contains` becomes `instr()` on SQLite, which is **case-sensitive**. Use
  `EF.Functions.Like(c.Name, $"%{term}%")` so it matches without case on both providers.
- [ ] Check: Aspire run is unchanged (SQL Server, migrations, Admin + Public still work).
- [ ] Document in both READMEs: "SQL Server is the system database. The SQLite provider exists only for the
  instructor-approved Azure deployment of the API used by the iOS course."

#### 0.2 Add the mobile auth the iOS spec requires (same branch)

The 4976 plan's D9 removed the mobile register flow, but the iOS spec requires `POST /api/auth/register` and
`POST /api/auth/login`.

- [ ] Add role `Voter` (`AppRoles.Voter`) and seed it. Voters have no `MunicipalityId` and get no write access.
  `TenantContextFilter` already treats non-admins as public read-only.
- [ ] `POST /api/auth/register` `{ name, email, password }` → creates a Voter (user name = email) and returns a JWT.
- [ ] `POST /api/auth/login`: accept Voters too (it currently returns 401 for non-admins). The Admin Blazor
  login still checks roles itself.
- [ ] `GET /api/auth/me` `[Authorize]` → `{ email, name, role }`, for "JWT used to identify the logged-in user".
- [ ] `POST /api/auth/firebase-token` `[Authorize(Roles = Voter)]` → Firebase custom token (see D2 below).
- [ ] Privacy check: voter accounts store only name, email and password hash. Selections never touch the API or
  SQL, so the 4976 privacy rules still hold. Note this in the 4976 docs.

#### 0.3 Deploy to Azure App Service

- [ ] Reuse the existing App Service `mems-isaac-cali-…westus3` (Linux, .NET 10), or create a new F1/B1 app if A1
  should stay live.
- [ ] App settings:
  - `Database__Provider=Sqlite`
  - `ConnectionStrings__memsdb=Data Source=/home/data/mems.db` (`/home` persists across restarts)
  - `Jwt__Key=<64+ random chars>` (Aspire generated this locally; on Azure you set it yourself)
  - `Firebase__ServiceAccountJson=<service account JSON>` (for 0.2's custom tokens)
- [ ] `dotnet publish MEMS.Api -c Release` → deploy (`az webapp deploy` or the VS Code Azure extension).
- [ ] Smoke test: `/api/swagger` loads; `GET /api/municipalities` returns 3 tenants;
  `GET /api/burnaby/candidates` returns only Burnaby; register → login → `/api/auth/me` with a Bearer token.

**Phase 0 exit:** the Azure URL serves seeded data from SQLite, and Aspire locally still runs on SQL Server from
the same commit.

---

## Architecture decisions (iOS)

| # | Decision | Why |
|---|---|---|
| D1 | `APIConfig.baseURL` = the Azure URL (local Aspire gateway `http://localhost:5001/api` under `#if DEBUG` if needed). Image URLs from the API are relative (`/api/burnaby/images/5`), so resolve them against the host. | Single API |
| D2 | **Firebase Auth with a custom token minted by our API.** After login, the app calls `/api/auth/firebase-token` and then `Auth.auth().signIn(withCustomToken:)`. The token carries an `email` claim. **Fallback if short on time:** Firebase Email/Password auth with the same credentials, created on register and signed in on login. | Firestore rules can only enforce "own data" when there's a `request.auth`. The custom token keeps the .NET API as the only identity source. |
| D3 | Municipality = the tenant **slug**, stored in Firestore `UserProfiles/{email}` `{ municipalitySlug, municipalityName, lastSync }`. No profile doc means first login, so show the municipality picker. | Spec Part 3: "stored in Firebase and associated with the authenticated user" |
| D4 | Selection doc ID = `{email}_{candidateId}`, so a duplicate save overwrites the same doc instead of creating a second one. The app still checks for duplicates first and shows a message. | Spec validation: duplicates not permitted |
| D5 | Seat limit = `Position.SeatsAvailable` from the API. Before creating, count the user's selections with that `positionId` in the current municipality. | "Pitt Meadows: 1 mayor, 5 councillors…" |
| D6 | Navigation: `NavigationSplitView` when `horizontalSizeClass == .regular` (iPad), `TabView` + `NavigationStack` when `.compact`. Selection and edit drafts live in view models owned above the size-class switch, so rotation keeps them. | Part 6, orientation-state rules |
| D7 | Folders: `Services/Auth` (Keychain, session), `Services/API` (APIClient, config, errors), `Services/Firebase` (FirestoreService, FirebaseAuthService), `ViewModels`, `Views`, `Models`. | Part 7 separation |

### Firestore model

```
CandidateSelections/{email}_{candidateId}
  userEmail, candidateId (int), candidateName, photoUrl,
  positionId (int), positionName, municipalitySlug, municipalityName,
  notes (≤500), dateCreated, dateModified (server timestamps)

UserProfiles/{email}
  municipalitySlug, municipalityName, lastSync
```

### Security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function isOwner(email) { return request.auth != null && request.auth.token.email == email; }

    match /UserProfiles/{email} {
      allow read, write: if isOwner(email);
    }
    match /CandidateSelections/{id} {
      allow read, delete: if isOwner(resource.data.userEmail);
      allow create: if isOwner(request.resource.data.userEmail)
                    && request.resource.data.notes.size() <= 500;
      allow update: if isOwner(resource.data.userEmail)
                    && request.resource.data.userEmail == resource.data.userEmail
                    && request.resource.data.notes.size() <= 500;
    }
  }
}
```

Queries must filter `userEmail == me` (plus `municipalitySlug == current`), or the rules reject them.

---

## Phases

### Phase 1 — A1 maintenance (5 marks)
- [ ] The A1 Municipalities / Candidates / Voting Guide tabs are still placeholders in `MainTabView`. Build the
      Candidate Directory and Candidate Detail views (A2 needs them anyway).
- [ ] Update models to the new API DTOs: slug-based routes, `photoUrl`, `seatsAvailable`, `electionDate`.
- [ ] Remove `SavedCandidate` + the `savedCandidates` API calls (replaced by Firestore).
- [ ] Log every fix for the maintenance report: issue → original problem → resolution.

### Phase 2 — Auth (10 marks)
- [ ] Register/login against the new API. JWT stays in Keychain (already in place) and is sent as Bearer on every request.
- [ ] 401 or an expired `expiresAt` → clear the session, sign out of Firebase, return to login with "Session expired".
- [ ] After API login → Firebase custom-token sign-in (D2). Logout signs out of both.

### Phase 3 — Firebase setup (10 marks)
- [ ] Create the Firebase project, add the iOS app (bundle ID), add `GoogleService-Info.plist` (git-ignore it if the repo is public; otherwise note it).
- [ ] SPM: `firebase-ios-sdk` → `FirebaseAuth`, `FirebaseFirestore`. Call `FirebaseApp.configure()` in the App init.
- [ ] Publish the security rules above. Screenshot the project, collections and rules.

### Phase 4 — Municipality configuration
- [ ] First login with no `UserProfiles` doc → municipality picker (from `GET /api/municipalities`).
- [ ] `SessionViewModel.municipality` drives every API call (`/api/{slug}/candidates`, `/positions`) and Firestore query.
- [ ] Profile → change municipality → save to Firestore → reload candidates, positions and selections. Old-city selections disappear because of the query filter.
- [ ] Show "City: Burnaby" in nav titles/subtitles on Home, Directory, Selections and Profile.

### Phase 5 — Candidate Selections CRUD (20 marks)
- [ ] `FirestoreService` (async/await): `selections(email:slug:)`, `create`, `update(notes:)`, `delete`, `profile`, `saveProfile`.
- [ ] `CandidateDetailView`: **Add Selection** (notes sheet), or **Edit Selection** / **Delete Selection** when already saved.
- [ ] **My Candidate Selections** screen: photo, name, municipality, position, notes, date saved; edit, swipe/delete with confirmation, `.refreshable`.
- [ ] Validation in the view model: no duplicates, notes ≤ 500 chars (live counter), required fields, seat limit per position (D5).
- [ ] Profile: email, total saved selections, last sync timestamp.

### Phase 6 — Adaptive UI (15 marks)
- [ ] Directory: `List` on iPhone portrait; extra columns/info in iPhone landscape (`ViewThatFits` or `verticalSizeClass == .compact`); `LazyVGrid(columns: [.adaptive(minimum: 260)])` on iPad.
- [ ] Detail: `ViewThatFits { HStack { photo; info }; VStack { photo; info } }`.
- [ ] iPad: `NavigationSplitView` (sidebar: Directory / Selections / Profile → content → detail).
- [ ] Test rotation on **iPhone 16** and **iPad Air** simulators. Check that navigation, auth, loaded data and the in-progress notes draft survive.

### Phase 7 — Errors, architecture, best practices (20 marks)
- [ ] Map errors to friendly messages: Firestore unavailable or permission denied, network offline, 401/expired, decoding failures.
- [ ] Move files into the folder layout (D7). Keep MVVM: views stay dumb, and services sit behind protocols with mocks for previews.

### Phase 8 — Docs (5 marks)
- [ ] Architecture diagram: SwiftUI app → Azure App Service (`MEMS.Api`, SQLite) + Firebase Auth/Firestore.
- [ ] Maintenance report, Firestore collection description, feature list, municipality config notes (dev city: Burnaby; stored in `UserProfiles`).
- [ ] Screenshots: login, register, directory, details, create/edit selection, list, Firestore data, and the 4 orientations.
- [ ] Azure API URL + GitHub URL.

## Order of work given the deadline

Phase 0 blocks everything that talks to Azure. While 0.1–0.3 are underway, Phases 3 and 6 can start against
`MockAPIClient` / a local Aspire run. Prioritise by marks: CRUD (20) → adaptive UI (15) → auth (10) / Firebase (10).

## Open items

1. Instructor's iOS A1 feedback, needed for the maintenance report.
2. Reuse the A1 App Service or create a new one? (Reusing takes the A1 MVC site offline.)
3. If the Firebase service-account setup on Azure blocks progress, switch to the D2 fallback (Firebase Email/Password).
