#!/bin/bash

# Brannigan Release Script
# Usage: ./release.sh

set -e

echo "Building Brannigan distribution..."

# Clean any previous builds
make clean 2>/dev/null || true

# Generate Makefile and build
perl Makefile.PL
make

# Run tests
echo "Running tests..."
make test

# Create distribution
echo "Creating distribution..."
make dist

# Find the created tarball
TARBALL=$(ls Brannigan-*.tar.gz | head -1)

if [ -z "$TARBALL" ]; then
    echo "Error: No distribution tarball found!"
    exit 1
fi

echo "Distribution created: $TARBALL"

echo ""
echo "To upload to CPAN:"
echo "1. Install CPAN::Uploader if not already installed:"
echo "   cpanm CPAN::Uploader"
echo ""
echo "2. Configure your PAUSE credentials in ~/.pause:"
echo "   user YOUR_PAUSE_ID"
echo "   password YOUR_PAUSE_PASSWORD"
echo ""
echo "3. Upload the distribution:"
echo "   cpan-upload $TARBALL"
echo ""
echo "Or use the web interface at:"
echo "https://pause.perl.org/pause/authenquery?ACTION=add_uri"

# Optional: Automatically upload if credentials exist
if [ -f ~/.pause ]; then
    read -p "Upload to CPAN now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v cpan-upload >/dev/null 2>&1; then
            echo "Uploading to CPAN..."
            cpan-upload "$TARBALL"
            echo "Upload complete!"
        else
            echo "cpan-upload not found. Install with: cpanm CPAN::Uploader"
            exit 1
        fi
    fi
fi

echo "Release process complete!"