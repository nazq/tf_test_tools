# Terraform GCP Test Image Builder

[![Build and Push Docker Images](https://github.com/nazq/tf_test_tools/actions/workflows/build.yml/badge.svg)](https://github.com/nazq/tf_test_tools/actions/workflows/build.yml)
[![Docker Image Size (go1.24.1)](https://img.shields.io/docker/image-size/ghcr.io/nazq/tf_test_tools/tf_test_tools:go1.24.1)](https://ghcr.io/nazq/tf_test_tools/tf_test_tools)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository provides lightweight Docker images specifically designed for Terraform testing on Google Cloud Platform (GCP). It leverages a matrix build in GitHub Actions to generate images for multiple Go versions, ensuring compatibility and flexibility. It includes:

* **Terraform:** For infrastructure as code management.
* **Google Cloud SDK (gcloud):** For interacting with Google Cloud services.
* **GolangCI-Lint:** For Go code linting and quality checks.
* **Bash:** For scripting and command-line operations.
* **Curl:** For making HTTP requests.
* **Git:** For version control.
* **Unzip:** For extracting compressed files.
* **Shellcheck:** For shell script analysis.
* **Python3 and Pip:** For Python scripting and package management.

These tools are pre-installed and configured within the Docker images to provide a ready-to-use environment for Terraform testing on GCP. The images are tagged with the corresponding Go version, allowing you to select the appropriate image for your project.