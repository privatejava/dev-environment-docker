#!/bin/bash

# Docker Image Build Script
# This script provides a systematic way to build the dev-environment Docker image

set -e  # Exit on error

# Configuration
IMAGE_NAME="${IMAGE_NAME:-dev-environment}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build the dev-environment Docker image systematically.

OPTIONS:
    -n, --name NAME        Image name (default: dev-environment)
    -t, --tag TAG          Image tag (default: latest)
    -f, --file FILE        Dockerfile path (default: Dockerfile)
    -c, --context PATH     Build context path (default: .)
    --no-cache             Build without using cache
    --pull                 Always pull base image before building
    --platform PLATFORM    Target platform (e.g., linux/amd64, linux/arm64)
    -v, --verbose          Verbose output
    -h, --help             Show this help message

EXAMPLES:
    $0                                    # Build with defaults
    $0 -t v1.0.0                          # Build with specific tag
    $0 --no-cache                         # Build without cache
    $0 --platform linux/amd64             # Build for specific platform
    $0 -n my-dev-env -t latest            # Custom name and tag

ENVIRONMENT VARIABLES:
    IMAGE_NAME        Override default image name
    IMAGE_TAG         Override default image tag
    DOCKERFILE        Override default Dockerfile path
    BUILD_CONTEXT     Override default build context

EOF
}

# Parse command line arguments
NO_CACHE=""
PULL=""
PLATFORM=""
VERBOSE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        -c|--context)
            BUILD_CONTEXT="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --pull)
            PULL="--pull"
            shift
            ;;
        --platform)
            PLATFORM="--platform $2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="--progress=plain"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate Dockerfile exists
if [[ ! -f "$DOCKERFILE" ]]; then
    print_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

# Full image name
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Print build information
print_info "Building Docker image..."
echo "  Image Name: $FULL_IMAGE_NAME"
echo "  Dockerfile: $DOCKERFILE"
echo "  Build Context: $BUILD_CONTEXT"
[[ -n "$NO_CACHE" ]] && echo "  Cache: Disabled"
[[ -n "$PULL" ]] && echo "  Pull: Enabled"
[[ -n "$PLATFORM" ]] && echo "  Platform: $PLATFORM"
echo ""

# Build the image
BUILD_CMD="docker build \
    ${NO_CACHE} \
    ${PULL} \
    ${PLATFORM} \
    ${VERBOSE} \
    -f $DOCKERFILE \
    -t $FULL_IMAGE_NAME \
    $BUILD_CONTEXT"

print_info "Executing: $BUILD_CMD"
echo ""

if eval "$BUILD_CMD"; then
    print_info "Build completed successfully!"
    echo ""
    print_info "Image details:"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    print_info "To run the container:"
    echo "  # Interactive bash (default):"
    echo "  docker run -it --rm $FULL_IMAGE_NAME"
    echo "  # SSH daemon mode:"
    echo "  docker run -d -p 2222:22 --name dev-env $FULL_IMAGE_NAME sshd"
    echo ""
    print_info "To inspect the image:"
    echo "  docker inspect $FULL_IMAGE_NAME"
else
    print_error "Build failed!"
    exit 1
fi

