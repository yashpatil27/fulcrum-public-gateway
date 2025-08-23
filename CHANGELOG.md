# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README with production-ready documentation
- CONTRIBUTING.md with detailed contribution guidelines
- Full Fulcrum server support with dedicated scripts
- Security-focused architecture documentation
- Performance and scalability information
- Troubleshooting guides with real examples
- Backup and disaster recovery procedures

### Changed
- Updated primary focus to Fulcrum server (while maintaining Electrs compatibility)
- Enhanced configuration management with better validation
- Improved script organization and error handling
- Updated domain configuration from electrs.bittrade.co.in to fulcrum.bittrade.co.in

### Fixed
- Configuration consistency across all scripts
- SSL certificate handling for domain changes
- Tunnel status reporting accuracy
- Documentation accuracy with real-world testing

### Security
- Enhanced firewall configuration documentation
- Improved SSH tunnel security practices
- Better SSL/TLS configuration guidance
- Security audit recommendations

## [1.0.0] - 2025-08-23

### Added
- Initial production release
- SSH reverse tunnel setup for CGNAT bypass
- Let's Encrypt SSL certificate integration
- Comprehensive monitoring and management scripts
- Support for both Electrs and Fulcrum servers
- VPS setup automation
- Home server setup automation
- Systemd service integration
- UFW firewall configuration
- nginx reverse proxy with health checks
- stunnel SSL termination for TCP connections

### Infrastructure
- Production deployment on fulcrum.bittrade.co.in
- VPS hosting on vm-374.lnvps.cloud (185.18.221.146)
- Home server running Linux Mint with 32GB RAM
- Bitcoin Core full node with Fulcrum indexer
- 24/7 operational uptime

### Documentation
- Complete setup guides
- Troubleshooting documentation
- Security best practices
- Performance optimization tips
- Real-world configuration examples

## [0.9.0] - 2025-08-18

### Added
- Beta release with core functionality
- Basic tunnel setup scripts
- Initial VPS configuration
- Electrs support implementation
- SSL certificate management

### Changed
- Migrated from manual setup to automated scripts
- Improved error handling and logging
- Enhanced security configuration

## [0.1.0] - 2025-08-17

### Added
- Initial project structure
- Basic SSH tunnel concept
- Proof of concept implementation
- Initial documentation

---

## Version History Summary

- **v1.0.0**: Production-ready release with full Fulcrum support
- **v0.9.0**: Beta release with core functionality
- **v0.1.0**: Initial proof of concept

## Migration Notes

### From v0.9.0 to v1.0.0
- Update `config.env` with new domain if switching to Fulcrum-focused setup
- Run `./scripts/update-configs.sh` to update all configuration files
- Restart services with `./scripts/tunnel-restart.sh`

### Configuration Changes
- `DOMAIN` variable now supports both electrs and fulcrum subdomains
- Enhanced SSL configuration for better security
- Improved logging and monitoring capabilities

## Support

For issues related to specific versions:
- **Current version issues**: Use GitHub Issues
- **Legacy version support**: Limited to security issues only
- **Migration help**: See documentation or GitHub Discussions

