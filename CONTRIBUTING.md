# Contributing to ZeroHost

Thank you for your interest in contributing to ZeroHost! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- Clear description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- OS and version information
- Logs (if applicable)

### Suggesting Features

Feature suggestions are welcome! Please:
- Check if the feature already exists or is planned
- Provide a clear use case
- Explain why it would be useful to others

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your fork
7. Create a pull request

### Code Style

- Use 4 spaces for indentation
- Follow existing bash script conventions
- Comment complex logic
- Use meaningful variable names
- Add error handling

### Testing

Before submitting:
- Test on a clean VM
- Test on supported OS versions (Ubuntu 20.04, 22.04, 24.04, Debian 11, 12)
- Verify all components install correctly
- Test uninstall process

## Development Setup

### Prerequisites
- Linux VM or server
- Root access
- Internet connection

### Testing Your Changes

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/zerohost.git
cd zerohost

# Make scripts executable
chmod +x *.sh

# Test installation (use a clean VM!)
sudo ./install.sh
```

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help others learn

## Questions?

Open an issue or discussion if you need help!

Thank you for contributing! 🎉
