#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Bash Release Generator for nextVersion
# Creates a clean, professional release package for bash-only distribution

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
CURRENT_VERSION=$(cat "$PROJECT_ROOT/VERSION" 2>/dev/null || echo "1.0.0")
RELEASE_NAME="nextVersion-bash-${CURRENT_VERSION}"
RELEASE_DIR="/tmp/${RELEASE_NAME}"
ARCHIVE_NAME="${RELEASE_NAME}.tar.gz"
SIGN_RELEASE="${SIGN_RELEASE:-0}"
GPG_KEY="${GPG_KEY:-}"

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Bash Release Generator for nextVersion

OPTIONS:
    -v, --version VERSION    Specify version (default: auto-detect from VERSION file)
    -o, --output DIR         Output directory (default: /tmp)
    -s, --sign               Sign the release with GPG
    -k, --key KEY            GPG key to use for signing
    -c, --clean              Clean up temporary files after creation
    -h, --help               Show this help message

EXAMPLES:
    $0                        # Create release with auto-detected version
    $0 -v 2.0.0              # Create release for specific version
    $0 -o ./releases         # Output to custom directory
    $0 -s -k "your@email.com" # Sign release with GPG
    $0 -c                    # Clean up after creation

ENVIRONMENT VARIABLES:
    SIGN_RELEASE             Set to 1 to enable GPG signing
    GPG_KEY                  GPG key identifier for signing
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            CURRENT_VERSION="$2"
            shift 2
            ;;
        -o|--output)
            RELEASE_DIR="$2"
            shift 2
            ;;
        -s|--sign)
            SIGN_RELEASE=1
            shift
            ;;
        -k|--key)
            GPG_KEY="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_AFTER=1
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! -d "$PROJECT_ROOT/bin" ]] || [[ ! -d "$PROJECT_ROOT/config" ]]; then
    print_error "This script must be run from the nextVersion project root directory"
    print_error "Expected structure: bin/ and config/ directories"
    exit 1
fi

# Function to validate GPG setup
validate_gpg() {
    if [[ $SIGN_RELEASE -eq 1 ]]; then
        if ! command -v gpg >/dev/null 2>&1; then
            print_error "GPG is required for signing but not found"
            exit 1
        fi
        
        if [[ -n "$GPG_KEY" ]]; then
            if ! gpg --list-keys "$GPG_KEY" >/dev/null 2>&1; then
                print_error "GPG key '$GPG_KEY' not found"
                exit 1
            fi
        else
            print_warning "No GPG key specified, will use default key"
        fi
    fi
}

# Function to create release directory structure
create_release_structure() {
    print_status "Creating release directory structure..."
    
    # Clean up existing release directory
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
    
    # Create subdirectories
    mkdir -p "$RELEASE_DIR/bin"
    mkdir -p "$RELEASE_DIR/config"
    mkdir -p "$RELEASE_DIR/docs"
    
    print_success "Release directory structure created"
}

# Function to copy essential files
copy_release_files() {
    print_status "Copying essential files..."
    
    # Copy bash scripts (exclude any symlinks)
    for script in "$PROJECT_ROOT/bin"/*.sh; do
        if [[ -f "$script" ]] && [[ ! -L "$script" ]]; then
            cp "$script" "$RELEASE_DIR/bin/"
            chmod +x "$RELEASE_DIR/bin/$(basename "$script")"
        fi
    done
    
    # Copy configuration
    cp -r "$PROJECT_ROOT/config"/* "$RELEASE_DIR/config/"
    
    # Copy documentation
    cp "$PROJECT_ROOT/LICENSE" "$RELEASE_DIR/"
    cp "$PROJECT_ROOT/VERSION" "$RELEASE_DIR/"
    
    # Copy relevant documentation
    cp "$PROJECT_ROOT/doc/VERSIONING.md" "$RELEASE_DIR/docs/"
    cp "$PROJECT_ROOT/doc/RELEASE_WORKFLOW.md" "$RELEASE_DIR/docs/"
    cp "$PROJECT_ROOT/doc/TAG_MANAGEMENT.md" "$RELEASE_DIR/docs/"
    
    # Copy release notes if available
    if [[ -d "$PROJECT_ROOT/release-notes" ]]; then
        cp -r "$PROJECT_ROOT/release-notes" "$RELEASE_DIR/"
        print_status "Release notes directory copied"
    fi
    
    print_success "Essential files copied"
}

# Function to create installation script
create_install_script() {
    print_status "Creating installation script..."
    
    # Create a simple install script template
    cat > "$RELEASE_DIR/install.sh" << 'EOF'
#!/bin/bash

# nextVersion Bash Tools Installation Script
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/nextVersion"

# Function to show usage
show_usage() {
    cat << 'USAGE_EOF'
Usage: $0 [OPTIONS]

Installation script for nextVersion bash tools

OPTIONS:
    -d, --dir DIR            Installation directory (default: ~/.local/bin)
    -c, --config DIR         Configuration directory (default: ~/.config/nextVersion)
    -h, --help               Show this help message

EXAMPLES:
    $0                        # Install to default locations
    $0 -d /usr/local/bin     # Install to system directory
    $0 -c /etc/nextVersion   # Install config to system location
USAGE_EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Create directories
print_status "Creating installation directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# Install scripts
print_status "Installing bash scripts to $INSTALL_DIR..."
cp bin/*.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/*.sh

# Install configuration
print_status "Installing configuration to $CONFIG_DIR..."
cp config/* "$CONFIG_DIR/"

# Update script paths to use new config location
print_status "Updating script configuration paths..."
for script in "$INSTALL_DIR"/*.sh; do
    if [[ -f "$script" ]]; then
        sed -i "s|../config/|$CONFIG_DIR/|g" "$script"
        sed -i "s|config/|$CONFIG_DIR/|g" "$script"
    fi
done

# Create symlinks for common commands
print_status "Creating convenient symlinks..."
cd "$INSTALL_DIR"

# Create symlinks for main tools
ln -sf semantic-version-analyzer.sh nextversion-analyze
ln -sf mathematical-version-bump.sh nextversion-bump
ln -sf version-calculator.sh nextversion-calc
ln -sf tag-manager.sh nextversion-tags

print_success "Installation completed successfully!"

# Show next steps
echo
print_status "Next steps:"
echo "1. Add $INSTALL_DIR to your PATH if not already there:"
echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
echo "   # Add to ~/.bashrc or ~/.zshrc for persistence"
echo
echo "2. Test the installation:"
echo "   nextversion-analyze --help"
echo "   nextversion-bump --help"
echo
echo "3. Configuration is available in: $CONFIG_DIR"
echo "   Edit $CONFIG_DIR/versioning.yml to customize behavior"
echo
print_success "nextVersion bash tools are now ready to use!"
EOF

    chmod +x "$RELEASE_DIR/install.sh"
    print_success "Installation script created"
}

# Function to create bash-only README
create_bash_readme() {
    print_status "Creating bash-only README..."
    
    cat > "$RELEASE_DIR/README.md" << 'EOF'
# nextVersion - Bash Versioning Tools

A collection of bash scripts for automated semantic versioning and release management.

## Quick Start

```bash
# Analyze your repository and suggest next version
./bin/semantic-version-analyzer.sh

# Automatically bump version based on changes
./bin/mathematical-version-bump.sh --commit

# Calculate version with LOC delta
./bin/version-calculator-loc.sh
```

## Scripts

- **semantic-version-analyzer.sh** - Main version analysis tool
- **mathematical-version-bump.sh** - Automated version bumping
- **version-calculator.sh** - Version calculation utilities
- **version-calculator-loc.sh** - LOC-based version calculation
- **tag-manager.sh** - Git tag management
- **git-operations.sh** - Git operations utilities
- **cli-options-analyzer.sh** - CLI options analysis
- **security-keyword-analyzer.sh** - Security analysis
- **keyword-analyzer.sh** - Keyword analysis
- **file-change-analyzer.sh** - File change analysis
- **ref-resolver.sh** - Reference resolution
- **generate-ci-gpg-key.sh** - CI GPG key generation
- **version-utils.sh** - Version utilities
- **version-config-loader.sh** - Configuration loading
- **version-validator.sh** - Version validation

## Configuration

Edit `config/versioning.yml` to customize bonus points, multipliers, and thresholds.

## Installation

Copy the `bin/` directory to your PATH or run scripts directly from this directory.

## License

GPLv3 - See LICENSE file for details.
EOF

    print_success "Bash-only README created"
}

# Function to create uninstall script
create_uninstall_script() {
    print_status "Creating uninstall script..."
    
    cat > "$RELEASE_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# nextVersion Bash Tools Uninstallation Script
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/nextVersion"

# Function to show usage
show_usage() {
    cat << 'USAGE_EOF'
Usage: $0 [OPTIONS]

Uninstallation script for nextVersion bash tools

OPTIONS:
    -d, --dir DIR            Installation directory (default: ~/.local/bin)
    -c, --config DIR         Configuration directory (default: ~/.config/nextVersion)
    -k, --keep-config        Keep configuration files
    -h, --help               Show this help message

EXAMPLES:
    $0                        # Uninstall from default locations
    $0 -d /usr/local/bin     # Uninstall from system directory
    $0 -k                    # Keep configuration files
USAGE_EOF
}

# Parse command line arguments
KEEP_CONFIG=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_DIR="$2"
            shift 2
            ;;
        -k|--keep-config)
            KEEP_CONFIG=1
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Confirm uninstallation
echo -e "${YELLOW}This will remove nextVersion bash tools from your system.${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Uninstallation cancelled"
    exit 0
fi

# Remove scripts
print_status "Removing bash scripts from $INSTALL_DIR..."
if [[ -d "$INSTALL_DIR" ]]; then
    rm -f "$INSTALL_DIR"/semantic-version-analyzer.sh
    rm -f "$INSTALL_DIR"/mathematical-version-bump.sh
    rm -f "$INSTALL_DIR"/version-calculator.sh
    rm -f "$INSTALL_DIR"/version-calculator-loc.sh
    rm -f "$INSTALL_DIR"/tag-manager.sh
    rm -f "$INSTALL_DIR"/git-operations.sh
    rm -f "$INSTALL_DIR"/cli-options-analyzer.sh
    rm -f "$INSTALL_DIR"/security-keyword-analyzer.sh
    rm -f "$INSTALL_DIR"/keyword-analyzer.sh
    rm -f "$INSTALL_DIR"/file-change-analyzer.sh
    rm -f "$INSTALL_DIR"/ref-resolver.sh
    rm -f "$INSTALL_DIR"/generate-ci-gpg-key.sh
    rm -f "$INSTALL_DIR"/version-utils.sh
    rm -f "$INSTALL_DIR"/version-config-loader.sh
    rm -f "$INSTALL_DIR"/version-validator.sh
    
    # Remove symlinks
    rm -f "$INSTALL_DIR"/nextversion-analyze
    rm -f "$INSTALL_DIR"/nextversion-bump
    rm -f "$INSTALL_DIR"/nextversion-calc
    rm -f "$INSTALL_DIR"/nextversion-tags
fi

# Remove configuration
if [[ $KEEP_CONFIG -eq 0 ]] && [[ -d "$CONFIG_DIR" ]]; then
    print_status "Removing configuration from $CONFIG_DIR..."
    rm -rf "$CONFIG_DIR"
else
    print_status "Keeping configuration files in $CONFIG_DIR"
fi

print_success "Uninstallation completed successfully!"
EOF

    chmod +x "$RELEASE_DIR/uninstall.sh"
    print_success "Uninstall script created"
}

# Function to parse and copy release notes from project root
parse_release_notes() {
    print_status "Parsing release notes from project root..."
    
    # Try to find release notes for the current version
    RELEASE_NOTES_SOURCE=""
    
    # Check for version-specific release notes
    if [[ -f "$PROJECT_ROOT/release-notes/v${CURRENT_VERSION}.md" ]]; then
        RELEASE_NOTES_SOURCE="$PROJECT_ROOT/release-notes/v${CURRENT_VERSION}.md"
        print_status "Found version-specific release notes: v${CURRENT_VERSION}.md"
    elif [[ -f "$PROJECT_ROOT/release-notes/README.md" ]]; then
        RELEASE_NOTES_SOURCE="$PROJECT_ROOT/release-notes/README.md"
        print_status "Using release notes index as fallback"
    else
        print_warning "No release notes found in project root"
        return 1
    fi
    
    if [[ -n "$RELEASE_NOTES_SOURCE" ]]; then
        # Copy existing release notes
        cp "$RELEASE_NOTES_SOURCE" "$RELEASE_DIR/RELEASE_NOTES.md"
        
        # Update the release notes with current information
        sed -i "s/Version ${CURRENT_VERSION}/Version ${CURRENT_VERSION} - Release Package/g" "$RELEASE_DIR/RELEASE_NOTES.md"
        
        # Add package information at the end
        cat >> "$RELEASE_DIR/RELEASE_NOTES.md" << EOF

---

## 📦 **Release Package Information**

**Package Name**: ${RELEASE_NAME}  
**Generated On**: $(date)  
**Package Size**: $(du -sh "$RELEASE_DIR" | cut -f1)  
**Installation**: Run \`./install.sh\` after extraction

### **Package Contents**
- \`bin/\` - All bash scripts (executable)
- \`config/\` - Configuration files
- \`docs/\` - Essential documentation
- \`install.sh\` - Installation script
- \`uninstall.sh\` - Uninstallation script

### **Quick Installation**
\`\`\`bash
# Extract and install
tar -xzf ${ARCHIVE_NAME}
cd ${RELEASE_NAME}
./install.sh

# Test installation
nextversion-analyze --help
\`\`\`
EOF
        
        print_success "Release notes copied and updated from project source"
    fi
}

# Function to create package
create_package() {
    print_status "Creating release package..."
    
    cd "$(dirname "$RELEASE_DIR")"
    
    if [[ $SIGN_RELEASE -eq 1 ]]; then
        print_status "Creating signed release package..."
        tar -czf "${ARCHIVE_NAME}.tmp" "$(basename "$RELEASE_DIR")"
        
        if [[ -n "$GPG_KEY" ]]; then
            gpg --armor --detach-sign --local-user "$GPG_KEY" "${ARCHIVE_NAME}.tmp"
        else
            gpg --armor --detach-sign "${ARCHIVE_NAME}.tmp"
        fi
        
        mv "${ARCHIVE_NAME}.tmp" "$ARCHIVE_NAME"
        print_success "Signed release package created: $ARCHIVE_NAME"
    else
        tar -czf "$ARCHIVE_NAME" "$(basename "$RELEASE_DIR")"
        print_success "Release package created: $ARCHIVE_NAME"
    fi
}

# Function to show release summary
show_release_summary() {
    print_header "Release Summary"
    
    echo -e "${GREEN}Release Name:${NC} $RELEASE_NAME"
    echo -e "${GREEN}Version:${NC} $CURRENT_VERSION"
    echo -e "${GREEN}Package:${NC} $ARCHIVE_NAME"
    echo -e "${GREEN}Size:${NC} $(du -sh "$RELEASE_DIR" | cut -f1)"
    echo -e "${GREEN}Location:${NC} $RELEASE_DIR"
    
    if [[ $SIGN_RELEASE -eq 1 ]]; then
        echo -e "${GREEN}Signed:${NC} Yes"
        if [[ -n "$GPG_KEY" ]]; then
            echo -e "${GREEN}GPG Key:${NC} $GPG_KEY"
        fi
    else
        echo -e "${GREEN}Signed:${NC} No"
    fi
    
    echo
    print_status "Release contents:"
    ls -la "$RELEASE_DIR"
    
    echo
    print_status "Next steps:"
    echo "1. Test the release: cd $RELEASE_DIR && ./install.sh"
    echo "2. Distribute: $ARCHIVE_NAME"
    echo "3. Clean up: rm -rf $RELEASE_DIR"
    
    if [[ $SIGN_RELEASE -eq 1 ]]; then
        echo "4. Verify signature: gpg --verify $ARCHIVE_NAME.sig"
    fi
}

# Function to cleanup
cleanup() {
    if [[ ${CLEAN_AFTER:-0} -eq 1 ]]; then
        print_status "Cleaning up temporary files..."
        rm -rf "$RELEASE_DIR"
        print_success "Cleanup completed"
    fi
}

# Main execution
main() {
    print_header "nextVersion Bash Release Generator"
    
    print_status "Project root: $PROJECT_ROOT"
    print_status "Version: $CURRENT_VERSION"
    print_status "Release directory: $RELEASE_DIR"
    
    # Validate environment
    validate_gpg
    
    # Create release
    create_release_structure
    copy_release_files
    create_install_script
    create_uninstall_script
    create_bash_readme
    parse_release_notes
    
    # Create package
    create_package
    
    # Show summary
    show_release_summary
    
    # Cleanup if requested
    cleanup
    
    print_success "Release generation completed successfully!"
}

# Run main function
main "$@"
