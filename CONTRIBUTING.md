# Contributing to Bitcoin Fulcrum Server Public Gateway

Thank you for your interest in contributing! This guide will help you get started.

## 🎯 Ways to Contribute

### 1. Bug Reports
- Use GitHub Issues for bug reports
- Include detailed logs and system information
- Describe steps to reproduce the issue
- Include your configuration (sanitized)

### 2. Feature Requests
- Use GitHub Discussions for feature requests
- Explain the use case and expected behavior
- Consider backward compatibility

### 3. Documentation
- Improve README clarity
- Add troubleshooting steps
- Translate documentation
- Add examples and tutorials

### 4. Code Contributions
- Fix bugs
- Add new features
- Improve performance
- Add tests

## 🛠️ Development Setup

### Prerequisites
- Linux development environment
- Bitcoin Core node (for testing)
- Fulcrum server (for testing)
- Access to a test VPS
- Basic knowledge of bash scripting

### Local Development
```bash
# Fork and clone the repository
git clone https://github.com/yourusername/electrs-public-gateway.git
cd electrs-public-gateway

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Test thoroughly on your setup

# Run validation
./scripts/validate-config.sh

# Commit and push
git commit -m "Add: your feature description"
git push origin feature/your-feature-name
```

### Testing Guidelines
- Test on clean environments when possible
- Verify scripts work with different configurations
- Test both Electrs and Fulcrum compatibility
- Check SSL certificate generation
- Verify tunnel connectivity

## 📝 Code Standards

### Bash Scripts
- Use `#!/bin/bash` shebang
- Add proper error handling with `set -e`
- Include helpful comments
- Use descriptive variable names
- Follow existing code style
- Add input validation

### Documentation
- Use clear, concise language
- Include practical examples
- Update README.md for significant changes
- Add inline comments in complex scripts

### Configuration
- Maintain backward compatibility
- Document new configuration options
- Provide sensible defaults
- Include validation

## 🔒 Security Considerations

### Security Review Required
- Changes to SSL/TLS handling
- Modifications to SSH tunnel setup
- Firewall rule changes
- Certificate management updates

### Security Best Practices
- Never commit private keys or certificates
- Sanitize logs before sharing
- Use secure defaults
- Validate all inputs
- Follow principle of least privilege

## 📋 Pull Request Process

### Before Submitting
1. **Test thoroughly** on your own setup
2. **Update documentation** if needed
3. **Run validation scripts** to ensure quality
4. **Check for conflicts** with latest main branch
5. **Write clear commit messages**

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Other (specify)

## Testing
- [ ] Tested on home server setup
- [ ] Tested VPS configuration
- [ ] Tested SSL certificate generation
- [ ] Tested tunnel connectivity
- [ ] Tested with wallet connections

## Checklist
- [ ] Code follows project style
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No sensitive information included
```

### Review Process
1. **Automated checks** run on all PRs
2. **Manual review** by maintainers
3. **Testing** on different environments
4. **Security review** for security-related changes
5. **Merge** after approval

## 🐛 Reporting Bugs

### Bug Report Template
```markdown
**Describe the Bug**
A clear description of the bug

**To Reproduce**
Steps to reproduce the behavior

**Expected Behavior**
What you expected to happen

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Bitcoin Core version: [e.g., 25.0]
- Fulcrum version: [e.g., 1.9.0]
- VPS OS: [e.g., Ubuntu 20.04]

**Configuration:**
```bash
# Sanitized config.env (remove sensitive info)
```

**Logs:**
```
# Relevant log excerpts (remove sensitive info)
```

**Additional Context**
Any other context about the problem
```

## 🚀 Feature Requests

Use GitHub Discussions for feature requests with:
- **Use case**: Why is this needed?
- **Proposed solution**: How should it work?
- **Alternatives**: Other approaches considered?
- **Impact**: Who would benefit from this?

## 📚 Documentation

### Types of Documentation
- **README.md**: Main documentation
- **Script comments**: Inline documentation
- **Troubleshooting**: Common issues and solutions
- **Examples**: Real-world usage examples

### Documentation Standards
- Use clear, step-by-step instructions
- Include code examples
- Explain the "why" not just the "how"
- Keep it up-to-date with code changes
- Use proper markdown formatting

## 🎨 Style Guidelines

### Bash Scripts
```bash
#!/bin/bash
# Brief description of script purpose

set -e  # Exit on error

# Constants in UPPER_CASE
readonly CONFIG_FILE="config.env"

# Functions use snake_case
check_requirements() {
    local required_cmd="$1"
    if ! command -v "$required_cmd" >/dev/null 2>&1; then
        echo "Error: $required_cmd is required but not installed"
        return 1
    fi
}

# Main execution
main() {
    echo "Starting script..."
    check_requirements "bitcoin-cli"
    # ... rest of script
}

# Call main function
main "$@"
```

### Configuration Files
- Use descriptive variable names
- Group related settings
- Include comments explaining options
- Provide examples

## 🏷️ Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

## 📞 Getting Help

- **GitHub Discussions**: For general questions
- **GitHub Issues**: For bug reports
- **Email**: For security-related issues
- **Documentation**: Check README and inline comments first

## 🙏 Recognition

Contributors will be recognized in:
- README.md acknowledgments
- Release notes
- GitHub contributors list

Thank you for contributing to the Bitcoin ecosystem! 🧡
