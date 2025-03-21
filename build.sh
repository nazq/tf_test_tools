#!/bin/bash

set -euo pipefail

# Function to generate Dockerfile with specified Go version
generate_dockerfile() {
  local go_version="$1"
  local tf_version="1.11.2" # You can make this configurable too if needed

  cat <<EOF
# ---- STAGE 1: Golang Build Environment ----
FROM golang:${go_version}-alpine AS builder

# Install dependencies for Go tools
RUN apk add --no-cache \\
    git curl wget bash make binutils gcc musl-dev

# Set Go Path
ENV GOPATH=/go
ENV PATH=\$GOPATH/bin:/usr/local/go/bin:\$PATH

# Install GolangCI-Lint (built in this stage, copied later)
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \\
    && strip \$GOPATH/bin/golangci-lint  # Reduce binary size

# Make GO_VERSION available for RUN commands
ENV GO_VERSION=${go_version}
ENV TF_VERSION=${tf_version}

# Set GOPATH explicitly
ENV GOPATH=/root/go
ENV PATH=\$GOPATH/bin:\$PATH

# Install required dependencies
RUN apk add --no-cache \\
    curl wget unzip git \\
    shellcheck gnupg bash python3 py3-pip ca-certificates libc6-compat \\
    && echo "Installing Go \${GO_VERSION}..." \\
    && wget -O go.tar.gz "https://go.dev/dl/go\${GO_VERSION}.linux-amd64.tar.gz" \\
    && tar -C /usr/local -xzf go.tar.gz \\
    && rm go.tar.gz \\
    && ln -s /usr/local/go/bin/go /usr/local/bin/go

RUN echo "Installing Terraform..." \\
    && wget -O terraform.zip https://releases.hashicorp.com/terraform/\${TF_VERSION}/terraform_\${TF_VERSION}_linux_amd64.zip \\
    && unzip terraform.zip -d /usr/local/bin/ \\
    && rm terraform.zip

RUN echo "Installing Google Cloud SDK..." \\
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz \\
    && tar -xvzf google-cloud-cli-linux-x86_64.tar.gz \\
    && mv google-cloud-sdk /usr/local/ \\
    && /usr/local/google-cloud-sdk/install.sh --quiet \\
    && ln -s /usr/local/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud \\
    #&& gcloud components remove bq gsutil kubectl --quiet \\
    && rm -rf /usr/local/google-cloud-sdk/.install/.backup \\
    && rm google-cloud-cli-linux-x86_64.tar.gz

RUN echo "Installing GolangCI-Lint..." \\
    && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \\
    && mv \$GOPATH/bin/golangci-lint /usr/local/bin/ \\
    && go clean -modcache -cache \\
    && rm -rf \$GOPATH/pkg \$GOPATH/src \$GOPATH/bin

RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# ---- FINAL STAGE: Minimal Runtime Image ----
FROM golang:${go_version}-alpine

# Set up paths
ENV GOPATH=/root/go
ENV PATH=\$GOPATH/bin:/usr/local/bin:/usr/local/google-cloud-sdk/bin:\$PATH

# Install essential runtime tools
RUN apk add --no-cache \\
    bash curl git unzip shellcheck python3 py3-pip

# Copy pre-built binaries from the previous stages
COPY --from=builder /go/bin/golangci-lint /usr/local/bin/golangci-lint
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/local/google-cloud-sdk /usr/local/google-cloud-sdk
COPY --from=builder /usr/local/bin/tflint /usr/local/bin/tflint
RUN tflint --init

CMD ["bash"]
EOF
}

# Main script logic
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <go_version>"
  exit 1
fi

proj="tf_test_tools"
go_version="$1"

# Generate Dockerfile
generate_dockerfile "$go_version" > Dockerfile.go${go_version}

# Build and tag the Docker image
docker build -t ${proj}:go${go_version} -f Dockerfile.go${go_version} .

# Optional cleanup: remove the generated Dockerfile
# rm Dockerfile.go${go_version}

echo "Docker image ${proj}:go${go_version} built successfully."