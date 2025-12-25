# AssignMates — Plan

> **Package:** `assignmates.notesmates.in`
>
> **Goal:** Build a production-ready Flutter app that connects engineering students with vetted writers who can help complete handwritten or typed assignment solutions. Secure, scalable, simple onboarding and request flow, with PDF/image upload, Google sign-in, and S3-backed file storage.

---

## 1. High-level objectives

* Ship an MVP that lets students request assignment help and writers accept and deliver completed work.
* Use Firebase for auth, real-time data sync, notifications and analytics; use AWS S3 for storing PDFs/images (large binary storage).
* Smooth onboarding (intro slider + stepwise details), dark/light theme support, and industry-standard code structure and CI.

---

## 2. MVP feature list (must-have)

* Google Sign-in (Firebase Auth).
* Student onboarding (stepwise): location, college selection, allow notifications, camera permission, sample file upload.
* Default role: **student**. Writers are assigned by admin.
* Home (student): Create Request (subject, description, files, diagram checkbox, answer key optional).
* Matching: find available writer(s) and send offer; writer accepts or rejects.
* Payments: request advance payment before writer starts (escrow-like hold). Cancellation allowed within 30 minutes.
* Upload & storage: files uploaded to AWS S3 via presigned URLs; metadata stored in Firestore.
* Notifications via FCM for request updates and chat messages.
* In-app chat between student and writer (attachments + timestamps).
* Delivery & rating: writer uploads final PDF/image; student confirms and rates.
* Admin panel (web) for approving writers, seeing requests, and resolving disputes.

---

## 3. Tech stack

* Frontend mobile: **Flutter** (single codebase for Android & iOS).
* Auth/Realtime DB: **Firebase Auth** + **Cloud Firestore** (lightweight real-time features). Use Firestore rules for security.
* File storage: **AWS S3** (store large files). Use server-side presigned URLs for uploads.
* Backend admin / business logic: **Cloud Functions (Firebase) / Node.js** microservices for sensitive operations (presigned URL generation, payments webhook handling, writer matching). Admin web UI: Next.js or simple React app.
* Push notifications: **Firebase Cloud Messaging (FCM)**.
* Payments: integrate a local payment gateway that supports in-app SDK/webhooks (choose one suitable for your country/market). Keep payment logic in backend.
* CI/CD: GitHub Actions for build/test and Fastlane for release automation.

---

## 4. App flows (user stories)

### 4.1 First open

1. Splash screen (branded mockup + subtle animation).
2. Intro slider showing features (3–5 cards) and CTA: "Continue with Google".
3. If user chooses Google:

   * If account **exists** in Firestore: fetch profile, proceed to home.
   * If account **new**: create user doc with `role: student` and show stepwise onboarding.

### 4.2 Onboarding (stepwise)

* Step 1: Choose/confirm display name & profile photo.
* Step 2: Select college from verified list (autocomplete/search). Option: "My college not listed" -> request verification.
* Step 3: Location permission -> capture city/coordinates for nearby writer matching.
* Step 4: Allow notifications (request permission) and camera access (explain use case).
* Step 5: Upload sample file (optional) to test upload flow.

Persist partial onboarding data locally (shared_preferences) so users can resume.

### 4.3 Create Request (student)

* Form fields: subject (dropdown), topic/title, description, diagram checkbox, deadline, attach files (image/pdf), answer key (optional), preferred writer gender/language (optional), delivery preference (digital or physical if supported).
* On submit: create `request` document in Firestore with `status: open` and `createdAt`.
* Matching: run a Cloud Function to find nearby available writers (by location, rating, and workload). Notify top N writers.
* Writers get push + in-app notification. When a writer accepts, set `status: accepted_by_writer` and lock request.

### 4.4 Payment & Start

* After writer accepts, prompt student for advance payment (percent of total) before writer starts.
* Payment processed via backend; upon success, set `status: in_progress` and mark payment as `held`.
* Allow cancellation within 30 minutes: if canceled, refund flow handled via backend.

### 4.5 Delivery & Review

* Writer uploads final files to S3, marks `status: delivered` with `deliveredAt`.
* Student reviews and confirms within configurable window. Once confirmed, payment is released to writer.
* Student rates writer (1–5) and leaves a short review.

---

## 5. Data models (Firestore collections)

* `users`:

  * `uid`, `displayName`, `email`, `photoURL`, `role` (`student`/`writer`/`admin`), `collegeId`, `location` (lat/lng, city), `isWriterApproved` (bool), `rating`, `createdAt`.

* `colleges`:

  * `id`, `name`, `verified` (bool), `city`, `aliases`.

* `requests`:

  * `id`, `studentId`, `subject`, `title`, `description`, `diagramIncluded` (bool), `files` (array of metadata: s3Url, mimeType, filename, size), `answerKeyProvided` (bool), `deadline`, `status`, `matchedWriterId`, `price`, `createdAt`, `updatedAt`.

* `chats` (subcollection under `requests` or separate with `requestId`): messages with `senderId`, `text`, `attachments`, `createdAt`.

* `payments`:

  * `id`, `requestId`, `studentId`, `writerId`, `amount`, `status` (`held`, `released`, `refunded`), `gatewayPaymentId`, `createdAt`.

* `writers_profile` (optional detailed profile): `skills`, `sampleWorks`, `deliveryTimeAvg`, `verifiedDocuments`.

* `audit_logs` and `admin_actions` for dispute resolution.

---

## 6. Folder structure (Flutter — `lib/`)

```
lib/
├─ main.dart
├─ app.dart            # app entry + theme provider wiring
├─ src/
│  ├─ models/          # User, Request, Payment, College models
│  ├─ services/        # AuthService, FirestoreService, StorageService (S3), PaymentService
│  ├─ providers/       # ThemeProvider, AuthProvider, RequestProvider
│  ├─ screens/
│  │  ├─ auth/         # SignIn, Onboarding steps
│  │  ├─ home/         # StudentHome, RequestForm, RequestDetail
│  │  ├─ writer/       # WriterDashboard, AcceptRequest
│  │  ├─ admin/        # (optional) Admin screens for local debug
│  │  ├─ common/       # ChatScreen, Profile, Settings
│  ├─ widgets/         # Reusable UI components
│  ├─ utils/           # validators, constants, helpers
│  ├─ themes/          # light.dart, dark.dart
│  └─ routes.dart
```

---

## 7. File upload strategy (S3 + Firestore metadata)

1. Client requests a presigned upload URL from backend (Cloud Function / Node endpoint) with file metadata (name, mime, size).
2. Backend validates user auth & quota, generates presigned PUT URL for S3, returns it to client.
3. Client uploads directly to S3 using the presigned URL (multipart if large). On success, client notifies backend with final S3 key and stores metadata in Firestore under request.
4. Use S3 lifecycle rules to archive/delete older files as per retention policy.

Security: presigned URLs must be short-lived (e.g., 5–15 minutes). Validate file type/size server-side.

---

## 8. Auth & roles

* Use Firebase Auth Google sign-in.
* Create Firestore user record on first sign-in with `role: student` by default.
* Admin has a separate admin console (web) to promote users to `writer` and toggle `isWriterApproved`.
* Enforce role-based access in Cloud Functions and Firestore security rules.

---

## 9. Writer matching logic (simple MVP)

* Criteria: active status, location radius (city-level or km radius), rating >= threshold, current workload < threshold.
* Select top N writers; notify them in order or broadcast with first-accept wins.
* Use a small Cloud Function to run matching (triggered when request created).
* Keep the algorithm simple at first; iterate with additional weights later (response time, success rate).

---

## 10. Payments

* Require advance payment after writer accepts (percentage configurable).
* Backend handles payment creation and webhooks to update `payments` collection.
* Keep funds in hold state; release after delivery & confirmation.
* Support refunds and disputes via admin panel.

> Implementation note: pick a payments provider suitable for your market and regulatory needs. Keep payment code on your server to avoid exposing secrets.

---

## 11. Notifications & chat

* Use FCM for push notifications.
* Use Firestore real-time listeners for in-app chat.
* Store message attachments in S3; store URLs in chat message objects.

---

## 12. Offline first & caching

* Cache user profile and recent requests locally (Hive or shared_preferences for small data, SQLite for larger offline history).
* Allow drafting a request offline and sync when online.

---

## 13. Analytics, monitoring & error tracking

* Firebase Analytics for events (request_created, writer_accepted, payment_completed, request_delivered).
* Use Sentry or Firebase Crashlytics for error monitoring.
* Log important backend transactions (payments, file uploads) and set alerts for failures.

---

## 14. Security

* Firestore rules for read/write per role.
* Validate presigned URL requests server-side.
* Rate-limit critical endpoints (matching, presigned URL requests).
* Sanitize file uploads and inspect metadata.
* Store minimal PII and adhere to applicable privacy rules.

---

## 15. Testing strategy

* Unit tests for models and utility functions.
* Widget tests for critical UI screens (onboarding, request form, chat).
* Integration tests for flows (auth -> onboarding -> create request).
* End-to-end smoke tests with Firebase emulators (Firestore, Auth) for repeatable CI runs.

---

## 16. CI/CD and release

* Use GitHub Actions to run `flutter analyze`, `flutter test`, and build artifacts.
* Use codemagic/fastlane or GitHub Actions to build app bundles and distribute to Play Store / App Store.
* Keep environment variables & secrets in GitHub encrypted secrets.

---

## 17. Admin panel (web)

* Minimal admin UI to:

  * Approve writers and view documents.
  * See open requests and their statuses.
  * Process refunds and mark disputes resolved.
  * Export basic analytics (requests per college, average delivery time).
* Build with Next.js + React; host on Vercel or Firebase Hosting.

---

## 18. Non-functional requirements

* Scalability: use Firestore and S3 to scale reads/writes/storage independently.
* Latency: optimize hot paths (matching & notifications) with Cloud Functions and caching.
* Observability: logging + metrics + crash reporting.

---

## 19. Roadmap & deliverables (phased)

**Phase 0 — Prep**

* Project repo + branch strategy
* Firebase project setup (Auth, Firestore, FCM, Analytics)
* AWS S3 bucket & IAM user for presigned URLs
* Basic design mockups (splash, intro slider, onboarding steps)

**Phase 1 — Core MVP**

* Google Sign-in + user creation
* Onboarding (stepwise) and college list integration
* Create Request UI + Firestore write
* Basic writer matching and notifications
* File upload flow to S3 via presigned URL
* Simple in-app chat and request lifecycle

**Phase 2 — Payments & polish**

* Integrate payments and backend webhooks
* Implement cancellation & refund logic
* Ratings & reviews
* Basic admin panel

**Phase 3 — Scale & polish**

* Improve matching algorithm
* Add offline drafts & sync
* Add analytics dashboards and monitoring
* Release to stores and iterate on UX

---

## 20. Deliverables for "antigravity" (what to hand off)

* `plan.md` (this file)
* Flutter repo scaffold with folder structure
* Postman collection / API docs for backend endpoints
* Admin web repo scaffold
* Minimal design kit (Figma frames for splash, onboarding, request form, chat)
* CI pipeline config
* Testing checklist

---

## 21. Checklist before launch

* [ ] Firestore security rules audited
* [ ] S3 bucket policies and lifecycle set
* [ ] Payment gateway tested end-to-end and webhooks validated
* [ ] Crashlytics/Sentry hooked and tested
* [ ] Admin panel ready for writer approval
* [ ] Legal: Terms of Service & Privacy Policy prepared
* [ ] Beta group recruited for closed testing

---

## 22. Further suggestions

* Keep writer approval manual in early stages to maintain quality.
* Start with city-level matching to simplify location logic.
* Track reasons for cancellations to improve process.
* Consider adding quick templates for common subjects to speed up writers.

---

If you want, I can scaffold the Flutter repo structure and generate starter code for: auth + onboarding screens + S3 presigned upload flow + Firestore models. Tell me which part you want first.
