# Notification Bridge Service

This Node.js service listens to your Firestore `notifications` collection in real-time and sends FCM Push Notifications to users.

It is designed to be hosted on **Render.com** (or any persistent Node.js hosting) to ensure 24/7 reliability without the "cold start" issues of Serverless Functions.

## 1. Setup Firebase Credentials

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Navigate to **Project Settings** -> **Service Accounts**.
3.  Click **Generate new private key**.
4.  A `.json` file will download. Rename it to `service-account.json`.
5.  **For Local Testing**: Place this file inside the `notification-service` folder.

> **⚠️ SECURITY WARNING**: Never commit `service-account.json` to GitHub. It gives full access to your database. Verify that `.gitignore` excludes it (or simply don't add it to git).

## 2. Local Testing

1.  Open a terminal in the `notification-service` directory:
    ```bash
    cd notification-service
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Start the bridge:
    ```bash
    npm start
    ```
4.  You should see: `Firebase Initialized with local file` and `Starting Firestore Listener...`.

## 3. Deploying to Render.com (Free)

To deploy securely without uploading the key file, we will use an Environment Variable.

### Step A: Push to GitHub
1.  Commit your `notification-service` folder to your private GitHub repository.
    -   *Make sure `service-account.json` is NOT included.*

### Step B: Create Render Service
1.  Log in to [Render.com](https://render.com).
2.  Click **New +** -> **Web Service**.
3.  Connect your GitHub repository.
4.  Settings:
    -   **Root Directory**: `notification-service`
    -   **Runtime**: Node
    -   **Build Command**: `npm install`
    -   **Start Command**: `node index.js`
    -   **Instance Type**: Free

### Step C: Add the Secret Key
1.  We need to convert your `service-account.json` into a text 
string for the server.
2.  Run this command in your terminal (Mac/Linux):
    ```bash
    base64 -i service-account.json | pbcopy
    ```
    *(This copies the encoded string to your clipboard)*.
3.  In Render dashboard, go to the **Environment** tab of your new service.
4.  Add a new Environment Variable:
    -   **Key**: `FIREBASE_SERVICE_ACCOUNT`
    -   **Value**: *[Paste the copied base64 string]*
5.  Click **Save Changes**. Render will deploy your service.

## Verify
Check the **Logs** tab in Render. You should see `Firebase Initialized with ENV variable` and `Starting Firestore Listener...`.
