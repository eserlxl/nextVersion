# nextVersion Release Notes

This directory contains release notes for all versions of nextVersion.

## 📋 **Available Releases**

### [Version 1.0.0](v1.0.0.md) - Bash-Only Release
**Release Date**: August 11, 2025  
**Type**: Major Release  
**Breaking Changes**: Yes

**Highlights**:
- Complete folder restructuring (dev-bin/ → bin/, dev-config/ → config/)
- Professional bash-only distribution
- Comprehensive installation system
- Updated documentation

### Version 0.9.0 (Pre-restructuring)
**Release Date**: Before August 11, 2025  
**Type**: Development Release  
**Breaking Changes**: No

**Highlights**:
- Initial bash tool development
- Basic semantic versioning
- LOC-based delta system
- Git integration

## 🔄 **Release Process**

1. **Development**: Features and fixes are developed in the main branch
2. **Testing**: Comprehensive testing in the test-workflows directory
3. **Release Notes**: Release notes are prepared in this directory
4. **Version Bump**: Version is incremented using the semantic versioning system
5. **Release**: Bash release generator creates the distribution package
6. **Distribution**: Release package is distributed to users

## 📝 **Release Note Format**

Each release note follows this structure:

- **Version and Date**: Clear version identification
- **Release Type**: Major, Minor, or Patch
- **Breaking Changes**: Any incompatible changes
- **What's New**: New features and improvements
- **Included Tools**: List of available scripts
- **Installation**: How to install the release
- **Configuration**: How to customize behavior
- **Quick Start**: Basic usage examples
- **Documentation**: Available documentation
- **Migration**: How to upgrade from previous versions
- **Known Issues**: Any current limitations
- **Future Plans**: Upcoming features

## 🚀 **Creating New Releases**

To create release notes for a new version:

1. Copy the previous version's file: `cp v1.0.0.md v1.1.0.md`
2. Update the version number and date
3. Modify content to reflect new changes
4. Update this README.md index
5. Commit the changes

## 📚 **Related Documentation**

- [VERSIONING.md](../doc/VERSIONING.md) - Versioning strategy
- [RELEASE_WORKFLOW.md](../doc/RELEASE_WORKFLOW.md) - Release process
- [TAG_MANAGEMENT.md](../doc/TAG_MANAGEMENT.md) - Tag management

---

*For the latest release information, check the most recent version file.*
