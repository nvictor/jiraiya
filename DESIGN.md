# Jiraiya Design

This document outlines the design principles and architecture for the Jiraiya application.

## Vision

Jiraiya is a native macOS application that acts as a companion to Jira. It's designed to help visualize and manage your work, focusing on outcomes and providing a clear overview of epics, stories, and progress across fiscal quarters.

## Architecture

*   **Language:** Swift
*   **UI Framework:** SwiftUI
*   **Data Persistence:**
    *   **GRDB.swift:** For storing story data in a local SQLite database.
    *   **UserDefaults:** For caching epic descriptions and storing user settings (outcomes, API credentials).
*   **API Interaction:** REST API for Jira Cloud.

## Core Features

*   **Jira Integration:**
    *   Connect to a Jira Cloud instance using an email and API token.
    *   Sync stories from a specified project and start date.
    *   Fetches issue details, including resolution date, parent epic, and comments.

*   **Outcome-Based Tracking:**
    *   Categorize stories into user-defined "Outcomes" based on keywords found in story titles and comments.
    *   Manage outcomes (add, edit, delete) with custom names, keywords, and colors.
    *   Reclassify all stored stories when outcome definitions are updated.

*   **Hierarchical Visualization:**
    *   Stories are organized and displayed in a fiscal quarter hierarchy.
    *   Navigate from a yearly overview of quarters down to epics, months, and individual stories.
    *   Views provide summaries of outcomes at each level (quarter, epic, month).

*   **Settings & Diagnostics:**
    *   An inspector panel provides access to Jira API settings, outcome management, and a database reset function.
    *   A console view logs application activity, including sync progress and errors.

## Data Flow

1.  **Configuration:** The user provides their Jira URL, email, API token, project key, and a start date for syncing issues.
2.  **Sync:** `JiraService` fetches all completed issues from Jira that match the criteria. It uses JQL and handles pagination.
3.  **Processing:** Each Jira issue is converted into a `Story` object. `OutcomeManager` analyzes the issue's title and comments to assign an `Outcome`.
4.  **Persistence:** The processed `Story` objects are saved to a local SQLite database via `DatabaseManager` (which uses GRDB). Epic descriptions are fetched and cached in `UserDefaults`.
5.  **Display:** The main `ContentView` fetches stories from the database. A helper function then structures them into a hierarchy of quarters, epics, and months for display in the UI.
6.  **Reclassification:** If the user modifies the outcome keywords, `OutcomeReclassifier` can be triggered to re-process all stored stories against the new rules without re-fetching from Jira (though it does re-fetch comments).