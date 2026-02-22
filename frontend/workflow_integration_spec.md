# Workflow Integration Specification

This document outlines the frontend and backend requirements for implementing a workflow toggle and an incoming webhook.

---

## 1. Workflow Toggle

This feature allows a user to enable or disable a specific workflow from the frontend application.

### Frontend Requirements

*   **UI Component:** A toggle switch (e.g., `Switch` widget in Flutter) should be displayed on the workflow's settings screen.
*   **State Display:** The toggle's state (on/off) must reflect the current status of the workflow as fetched from the backend.
*   **State Change:**
    *   When the user taps the toggle, the app must make an API call to the backend to update the workflow's state.
    *   The UI should show a loading indicator while the request is in progress.
    *   The toggle should be temporarily disabled during the API call to prevent multiple rapid changes.
*   **Error Handling:** If the API call fails, the UI must display an error message (e.g., a Snackbar or Toast) and revert the toggle to its previous state.

### Backend API Requirements

#### A. Get Workflow State

*   **Endpoint:** `GET /api/workflows/{workflow_id}/settings`
*   **Purpose:** Fetches the current settings for a workflow, including its enabled status.
*   **Response (Success - 200 OK):**
    ```json
    {
      "workflowId": "wf_12345",
      "isEnabled": true
    }
    ```
*   **Response (Error - 404 Not Found):**
    ```json
    {
      "error": "Workflow not found."
    }
    ```

#### B. Update Workflow State

*   **Endpoint:** `PATCH /api/workflows/{workflow_id}/settings`
*   **Purpose:** Updates the workflow's enabled status.
*   **Request Body:**
    ```json
    {
      "isEnabled": false
    }
    ```
*   **Response (Success - 200 OK):**
    ```json
    {
      "workflowId": "wf_12345",
      "isEnabled": false,
      "message": "Workflow updated successfully."
    }
    ```
*   **Response (Error):**
    *   `400 Bad Request`: Invalid request body.
    *   `404 Not Found`: Workflow not found.

---

## 2. Incoming Webhook

This feature provides a unique URL that an external service can call to trigger the workflow.

### Frontend Requirements

*   **Display URL:** The unique webhook URL should be displayed in a read-only text field.
*   **Copy to Clipboard:** A "Copy" button must be placed next to the URL. Tapping it copies the URL to the user's clipboard and shows a confirmation message (e.g., "URL copied!").
*   **Security Note:** A brief, clear warning should be displayed near the URL, advising the user to keep it secure, similar to an API key. Example: "Treat this URL like a password. Do not share it publicly."

### Backend API Requirements

#### A. Get Webhook Information

The webhook URL should be provided as part of the workflow settings endpoint.

*   **Endpoint:** `GET /api/workflows/{workflow_id}/settings`
*   **Response (Success - 200 OK):**
    ```json
    {
      "workflowId": "wf_12345",
      "isEnabled": true,
      "webhook": {
        "url": "https://api.your-service.com/webhooks/incoming/wh_abc123_xyz789",
        "lastTriggered": "2026-02-21T10:00:00Z"
      }
    }
    ```

#### B. Handle Incoming Webhook

*   **Endpoint:** `POST /webhooks/incoming/{webhook_id}`
*   **Purpose:** Receives data from an external service to trigger the workflow.
*   **Authentication:** The `{webhook_id}` serves as the secret/authenticator. Requests to non-existent webhook IDs should result in a `404 Not Found`.
*   **Logic:**
    1.  Upon receiving a request, the backend must first validate the `{webhook_id}`.
    2.  It must then check if the associated workflow is enabled (`isEnabled: true`). If disabled, the backend should immediately return a `422 Unprocessable Entity` response and stop processing.
    3.  If enabled, the backend proceeds to execute the workflow logic using the payload from the request body.
*   **Response (Success - 202 Accepted):**
    *   A `202` is recommended to indicate that the event has been received and will be processed, without making the external service wait for the workflow to complete.
    ```json
    {
      "status": "processing",
      "message": "Workflow trigger accepted."
    }
    ```
*   **Response (Error):**
    *   `400 Bad Request`: Payload is malformed or invalid.
    *   `404 Not Found`: The `{webhook_id}` does not exist.
    *   `405 Method Not Allowed`: Request was not a `POST`.
    *   `422 Unprocessable Entity`: The associated workflow is disabled.
    ```json
    {
        "error": "Workflow is disabled."
    }
    ```

---

## 3. Expected Web Behavior

This section defines how the web dashboard should interact with the workflow states.

### A. Real-time Updates
*   When a workflow is triggered via a webhook, the dashboard should ideally reflect the new state (e.g., "Processing" or "Updated") without a manual refresh.
*   The web UI should display the `lastTriggered` timestamp accurately.

### B. Sentiment Mapping
*   The dashboard must map the `sentiment_score` from the briefing data to the tactical UI palette:
    *   `score > 0.3`: Kinetic Green with glow.
    *   `score < -0.3`: Warning Red with glow.
    *   Otherwise: Neutral Cyan/Blue.

### C. Configuration Sync
*   Toggling a workflow in the "Intel Setup" should immediately update the `isEnabled` status on the backend, which in turn controls whether the incoming webhook is processed.

---

## 4. Expected Webhook Behavior

This section defines the technical and behavioral expectations for the incoming webhook ingestion.

### A. Payload Validation
*   The webhook must receive a valid JSON payload.
*   The backend should validate that the payload contains the necessary `data` structure required for the Daily Briefing.

### B. Security & Authentication
*   The `{webhook_id}` in the URL acts as the primary secret.
*   The backend must return a `404 Not Found` if the ID is incorrect to prevent leaking information about workflow existence.

### C. Response Logic
*   **Success (202 Accepted):** Returned immediately after validation to acknowledge receipt.
*   **Failure (422 Unprocessable Entity):** Returned if the workflow is currently disabled via the toggle.
