<!-- hero image -->

![status/experimental](https://img.shields.io/badge/STATUS-EXPERIMENTAL-%237C3AED?style=flat-square)
###### tsklabs • GitHub CLI Extension
# gh-topic <!-- omit in toc -->

Manage GitHub repository topics from the command line using `gh`.

## Contents

- [1. Overview](#1-overview)
  - [1.1 Features](#11-features)
  - [1.2 Start Here](#12-start-here)
- [2. Getting started](#2-getting-started)
  - [2.1. Prerequisites](#21-prerequisites)
  - [2.2. Install / Access](#22-install--access)
  - [2.3. Quickstart](#23-quickstart)
- [3. Tutorials](#3-tutorials)
- [4. How-to](#4-how-to)
- [5. Explanation](#5-explanation)
  - [5.1. Concepts](#51-concepts)
  - [5.2. Motivation](#52-motivation)
- [6. Reference](#6-reference)
  - [6.1. Architecture](#61-architecture)
  - [6.2. Interfaces / API / Commands](#62-interfaces--api--commands)
  - [6.3. Configuration](#63-configuration)
  - [6.4. Error Codes](#64-error-codes)
  - [6.5. Release Notes](#65-release-notes)
  - [6.6. Glossary](#66-glossary)
  - [6.7. Resources](#67-resources)
  - [6.8. Testing](#68-testing)
  - [6.9. FAQ](#69-faq)
- [7. Roadmap](#7-roadmap)
  - [7.1. Now](#71-now)
  - [7.2. Next](#72-next)
  - [7.3. Later](#73-later)
- [8. Contributing](#8-contributing)
  - [8.1. Instructions](#81-instructions)
  - [8.2. Code of Conduct](#82-code-of-conduct)
  - [8.3. Styleguide](#83-styleguide)
- [9. Feedback & Support](#9-feedback--support)
  - [9.1. Feedback](#91-feedback)
  - [9.2. Support](#92-support)
- [10. Maintainer(s)](#10-maintainers)
- [11. License](#11-license)

<br>

## 1. Overview

`gh-topic` is a shell-based GitHub CLI extension for adding and removing repository topics.
It is for maintainers who manage repository metadata and want repeatable CLI workflows.
It exists to make topic updates fast and scriptable without opening the GitHub web UI.

**Demo**

```bash
gh topic add --reponame tsklabs/gh-topic --names "cli,github,topics"
gh topic rm --reponame gh-topic --names "topics"
```

<br>

### 1.1 Features

- Add multiple topics in one command
- Remove one or more existing topics safely
- Supports `owner/repo` and `repo` forms (owner inferred from authenticated `gh` user)

<br>

### 1.2 Start Here

Pick what you want to do:

#### Onboard
Get started for the first time.
1. Follow [Getting started](#2-getting-started)
2. Complete one of the [Tutorials](#3-tutorials)
3. Use [Reference](#6-reference) to verify details and expected behavior

#### Operate
Complete a specific task or solve an immediate problem.
1. Go to [How-to](#4-how-to) for task-oriented procedures
2. Use [Reference](#6-reference) for exact technical details
3. Check [FAQ](#69-faq) and [Error Codes](#64-error-codes) when troubleshooting

#### Understand
Learn concepts, trade-offs, and design decisions.
1. Read [Explanation](#5-explanation)
2. Review [Architecture](#61-architecture)
3. Cross-check specifics in [Reference](#6-reference)

#### Contribute
Improve code, docs, tests, or other project assets.
1. Start with [Contributing](#8-contributing)
2. Read [Styleguide](#83-styleguide) and [Testing](#68-testing)
3. Review [Roadmap](#7-roadmap) to align with priorities

<br>

Still unsure?
- Learn by doing → [Tutorials](#3-tutorials)
- Solve a task now → [How-to](#4-how-to)
- Understand the design → [Explanation](#5-explanation)
- Look up exact details → [Reference](#6-reference)

<br>

## 2. Getting started

### 2.1. Prerequisites

- GitHub CLI (`gh`) installed
- Authenticated GitHub CLI session (`gh auth login`)
- Permission to edit topics on target repository

### 2.2. Install / Access

```bash
gh extension install tsklabs/gh-topic
```

To use a local clone during development:

```bash
gh extension install .
```

### 2.3. Quickstart

```bash
# Add topics
gh topic add --reponame tsklabs/gh-topic --names "shell,cli,metadata"

# Remove topics
gh topic rm --reponame tsklabs/gh-topic --names "metadata"

# Owner inferred from authenticated user
gh topic add --reponame gh-topic --names "experimental"
```

<br>

## 3. Tutorials

- Add your first set of repository topics
- Remove outdated repository topics
- Update topics in a scriptable CI/local workflow

<br>

## 4. How-to

- How to add topics to a repository you own
- How to remove one or many topics by name
- How to use short `--reponame repo` format with authenticated owner
- How to troubleshoot auth and permission failures

<br>

## 5. Explanation

### 5.1. Concepts

- **Topic set update**: topics are managed as a full set via GitHub GraphQL `updateTopics`
- **Set union (add)**: requested topics are merged with existing topics
- **Set difference (rm)**: requested topics are removed from existing topics

### 5.2. Motivation

GitHub's legacy topic suggestion mutations are no longer reliable for repo topic management.
This extension uses the supported `updateTopics` mutation to keep behavior stable.

<br>

## 6. Reference

### 6.1. Architecture

- Entry point: `gh-topic`
- Command scripts: `source/commands/add.sh`, `source/commands/rm.sh`
- Shared helpers: `source/extras/addons.sh`
- API surface: GitHub GraphQL via `gh api graphql`

### 6.2. Interfaces / API / Commands

```text
gh topic add -r|--reponame <owner/repo|repo> --names <comma-separated topics>
gh topic rm  -r|--reponame <owner/repo|repo> --names <comma-separated topics>
```

### 6.3. Configuration

No project-specific config file is required.
Behavior depends on your authenticated `gh` context.

### 6.4. Error Codes

| Error Code | Message | Cause | Resolution |
|------------|---------|-------|------------|
| AUTH_OWNER_MISSING | Unable to detect default GitHub owner | `--reponame repo` used without valid `gh` auth | Run `gh auth login` or pass `owner/repo` |
| REPO_NOT_FOUND | Repository not found / no ID | Invalid repository or missing access | Verify repo name and permissions |
| TOPIC_NOT_FOUND | Topic not found on repository (rm) | Trying to remove a topic that is not present | Check current topics and retry |
| UPDATE_FAILED | Fail to update topics | GraphQL/API mutation failed | Re-run with `--debug`; verify auth and permissions |

### 6.5. Release Notes

- Unreleased
  - Migrated add/remove flows to GraphQL `updateTopics`
  - Added owner inference consistency for both commands

### 6.6. Glossary

- **Topic**: repository classification label shown on GitHub
- **Repository ID**: GraphQL node identifier required by `updateTopics`

### 6.7. Resources

- GitHub CLI: https://cli.github.com/
- GitHub GraphQL API: https://docs.github.com/en/graphql
- Repository: https://github.com/tsklabs/gh-topic

### 6.8. Testing

```bash
bash -n gh-topic source/commands/add.sh source/commands/rm.sh source/extras/addons.sh
```

### 6.9. FAQ

<details><summary><b>FAQ-001</b>: &nbsp; Why does <code>--reponame repo</code> fail?</summary>

You are likely not authenticated with GitHub CLI, or your auth token cannot access the repository.

```text
Run: gh auth login
Then retry the command.
```
</details>

<details><summary><b>FAQ-002</b>: &nbsp; Can I add/remove multiple topics at once?</summary>

Yes. Pass a comma-separated list to `--names`.

```text
--names "topic-one, topic-two,topic-three"
```
</details>

<br>

## 7. Roadmap

### 7.1. Now

- Stabilize topic updates with current GraphQL API

### 7.2. Next

- Add automated command-level tests
- Improve structured error messages

### 7.3. Later

- Optional JSON output mode
- Batch operations across multiple repositories

<br>

## 8. Contributing

### 8.1. Instructions

1. Fork repository/project
2. Create branch
3. Commit changes
4. Push branch
5. Open Pull Request (or follow your contribution workflow)

### 8.2. Code of Conduct

Please follow respectful, collaborative behavior for all project interactions.

### 8.3. Styleguide

- Keep shell changes minimal and focused
- Preserve command UX and help text compatibility
- Validate scripts with `bash -n` before submitting

<br>

## 9. Feedback & Support

### 9.1. Feedback

Open an issue with:
- expected behavior
- actual behavior
- command used and debug output (`--debug`)

### 9.2. Support

Use GitHub issues in this repository for support and troubleshooting.

<br>

## 10. Maintainer(s)

`tsklabs` — `https://github.com/tsklabs`

<br>

## 11. License

(c) `2026` - `tsklabs`
Licensed under the repository license.
