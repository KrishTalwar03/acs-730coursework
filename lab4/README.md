# ACS730 Lab 4 — Docker Images and CI/CD

## Overview

This lab compares a naive Docker image with an optimized image and uses GitHub Actions to test, build, and smoke-test a Flask application. It also demonstrates pip caching, Docker layer caching, a composite action, a reusable workflow, and GitHub Container Registry (GHCR).

## Application

The Flask application exposes two endpoints:

- `/` — returns the application name and version.
- `/healthz` — returns JSON containing the application health status and version.

### Run the tests locally

From the repository root:

```bash
cd lab4
python3 -m pytest
```

Expected result: **3 tests pass**.

## Docker image comparison

### Measured image sizes

| Image | Base image | Observed size |
|---|---|---:|
| Naive | `python:latest` | 1.15 GB |
| Optimized | `python:3.12-slim-bookworm` | 130 MB |

The optimized image is substantially smaller because it uses a slim Python base image and installs only the required runtime dependencies.

### Build timing observations

| Measurement | Observed duration |
|---|---:|
| Initial naive build | 25.259 seconds |
| Naive rebuild after a source change | 4.823 seconds |
| Initial optimized build | 4.972 seconds |
| Optimized rebuild with cached layers | 0.699 seconds |
| Optimized rebuild after changing `app.py` | 0.241 seconds |
| Build without `.dockerignore` | 4.851 seconds |

These measurements were taken on the lab workstation. Build times can vary with cache state and system conditions.

### Dockerfile design

The naive Dockerfile uses the moving `python:latest` tag, copies the entire build context before installing dependencies, and runs as root. The build context included files such as `.git` and other files that are not required at runtime.

The optimized Dockerfile:

- Uses `python:3.12-slim-bookworm`.
- Copies `requirements.txt` before application source code.
- Installs dependencies using `pip install --no-cache-dir`.
- Copies `app.py` after dependency installation.
- Creates and uses a non-root user named `appuser`.
- Uses a JSON-form `CMD` to run Gunicorn.

The `.dockerignore` file excludes `.git`, `.github`, Python cache files, evidence images, Markdown files, and Dockerfiles from the build context.

### Run the optimized container

Build the image:

```bash
docker build -t acs730-lab4:slim lab4/
```

Start the container:

```bash
docker run -d --name lab4 -p 8000:8000 acs730-lab4:slim
```

Check the health endpoint:

```bash
curl http://localhost:8000/healthz
```

Expected response:

```json
{"status":"ok","version":"dev"}
```

Verify the runtime user:

```bash
docker exec lab4 whoami
```

Expected output:

```text
appuser
```

Remove the container when finished:

```bash
docker rm -f lab4
```

## GitHub Actions pipeline

The `lab4-ci.yml` workflow runs tests against Python 3.11 and 3.12. It builds a Docker image, smoke-tests the `/healthz` endpoint, and reports job results in the workflow summary.

The summary job runs even if an upstream job fails and re-raises upstream failures so the overall workflow does not incorrectly appear successful.

The workflow also uses a reusable Docker build workflow and a composite action for Python setup and dependency installation.

### Composite action

The composite action at `.github/actions/python-deps/action.yml` centralizes Python setup and dependency installation. It uses `actions/setup-python` with pip caching to avoid repeatedly downloading dependencies when the cache key matches.

### Reusable workflow

The reusable workflow at `.github/workflows/docker-build.yml` centralizes Docker image building, caching, tagging, and optional publishing.

The composite action is useful for reusing a sequence of steps within a job. The reusable workflow is useful for reusing a complete job with its own runner, permissions, inputs, and outputs.

## CI cache timing measurements

The following timings were observed in the available GitHub Actions screenshots.

| Measurement | Observed result |
|---|---|
| Earlier successful workflow run | 1 minute 6 seconds |
| Latest workflow rerun | 1 minute 23 seconds |
| Python 3.11 test job | 17 seconds |
| Python dependency setup composite step | 10 seconds |
| `setup-python` step within that action | 7 seconds |
| Docker build-and-push step | 5 seconds |
| Docker build summary | 5 seconds; 38% cached in the observed summary |
| Pip cache | Cache restored successfully |
| Docker layer cache | Multiple layers reported `CACHED` |

These are observed timings, not a controlled baseline/cache-miss/cache-hit comparison. The workflow duration can vary because of runner startup, queueing, artifact handling, and other steps.

| Run category | Pip/test timing | Docker build timing | Whole workflow timing |
|---|---|---|---|
| Baseline before caching | Not measured separately | Not measured separately | Not measured separately |
| Cache miss | Not measured separately | Not measured separately | Not measured separately |
| Cache hit / observed cached run | Python dependency setup: 10 seconds | Docker build step: 5 seconds | Workflow rerun: 1 minute 23 seconds |

The pip cache can avoid downloading dependencies again when a matching cache is restored. Docker layer caching can reuse layers whose inputs have not changed. A cache miss occurs when no matching reusable cache is available; a cache hit occurs when matching cache entries are restored.

The recorded observations show cache restoration and cached Docker layers, but they do not establish a controlled comparison of all three run categories.

## Experiment 1 — Change Docker layer order

**Prediction:** Copying application source before installing dependencies will make a source change invalidate the dependency-installation layer.

**Observed result:** The optimized image rebuilt in 0.699 seconds with cached layers and in 0.241 seconds after changing `app.py`. The earlier naive source-change rebuild took 4.823 seconds.

**Explanation:** The optimized Dockerfile copies `requirements.txt` and installs dependencies before copying `app.py`. Docker can therefore reuse the dependency layer when only the application source changes. The naive Dockerfile copies the entire context before installing dependencies, so source changes can invalidate the dependency-installation layer.

## Experiment 2 — Remove `.dockerignore`

**Prediction:** Removing `.dockerignore` can allow unnecessary files to enter the Docker build context and increase the context size.

**Observed result:** The build without `.dockerignore` completed in 4.851 seconds. Docker reported a 2 B build context in this run, so the experiment did not demonstrate a measurable increase in context size.

**Explanation:** `.dockerignore` excludes `.git`, `.github`, Python cache files, evidence images, Markdown files, and Dockerfiles from the build context. The context-size result was unexpectedly small, so this experiment is inconclusive about the impact on context size. The original `.dockerignore` was restored after the experiment.

## Image publishing and GHCR

The reusable Docker workflow is designed to publish an image to GitHub Container Registry when its `push` input is enabled. Publishing should be enabled only on `main`.

The image tag uses the first 12 characters of the Git commit SHA, for example:

```text
sha-<12-character-commit>
```

A SHA-based tag identifies the source revision used to build the image and avoids the ambiguity of a moving tag such as `latest`.

Publishing uses `GITHUB_TOKEN` and requires package-write permission for the publishing job. Other jobs should receive only the permissions they need.

The existence and pullability of the published package must be verified separately before publication is considered complete.

## GitHub Actions versus AWS-native CI/CD

GitHub Actions is practical for this lab because the source code and workflows are hosted on GitHub. It provides hosted runners, pull-request checks, workflow artifacts, and direct integration with the repository.

AWS-native services such as CodePipeline, CodeBuild, and Amazon ECR are useful when CI/CD needs to integrate closely with AWS IAM, AWS-hosted artifacts, and other AWS services. The choice depends on access controls, deployment targets, cost, audit requirements, and the organization's existing tools.

The ordinary test and Docker-build jobs do not require AWS credentials. AWS credentials should only be added when a workflow genuinely needs to access AWS. Temporary lab credentials should not be treated as permanent credentials.

## Evidence checklist

The following screenshots should be saved under `lab4/evidence/`:

- `image-sizes.png` — naive and optimized image sizes and relevant build output.
- `ci-graph.png` — successful GitHub Actions test, build, smoke-test, and summary graph.
- `ghcr-package.png` — published GHCR package and SHA-based image tag.
- `required-check.png` — required status-check demonstration showing the deliberately failing check.

Confirm that all four files exist before submitting.

## Final verification and cleanup

Before submission:

1. Verify all required source files and workflow files are present.
2. Confirm the README contains no unfinished placeholders.
3. Verify that GHCR publishing works on `main`.
4. Configure and demonstrate the required status check.
5. Run the lab validation script:

```bash
./scripts/check-lab.sh lab4
```

6. Commit and push the completed Lab 4 files.
7. Verify the final workflow on `main`.
8. Clean up Docker containers and unused images.
9. Return the AWS workstation to `t3.micro` and leave it stopped when finished.
