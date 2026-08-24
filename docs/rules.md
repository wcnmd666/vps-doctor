# Diagnostic rule catalog

Rules return evidence, not certainty. A skipped rule does not reduce the score.

| Rule | Category | Detects | Default impact |
|---|---|---|---:|
| SYS-001 | System | Unvalidated operating system | Low |
| SYS-002 | System | 1-minute load above 1.5× CPU count | Medium |
| SYS-003 | System | Clock not reporting NTP synchronization | Low |
| STO-001 | Storage | Root disk ≥85% / ≥95% | High / Critical |
| STO-002 | Storage | Root inode use ≥90% | High |
| STO-003 | Storage | Journals reported in GiB | Medium |
| MEM-001 | Memory | Available memory below configured percentage | High |
| MEM-002 | Memory | No swap with less than 4 GiB RAM | Medium |
| MEM-003 | Memory | Kernel OOM evidence during the last 24 hours | High |
| SVC-001 | Services | Failed systemd units | High |
| SVC-002 | Services | Reboot-required marker | Low |
| NET-001 | Network | Missing default route | Critical |
| NET-002 | Network | Public DNS lookup failure | High |
| NET-003 | Network | Listening TCP port inventory | Informational |
| SEC-001 | Security | No detectable host input firewall | High |
| SEC-002 | Security | Direct/root SSH policy risk | Low / High |
| SEC-003 | Security | SSH password authentication enabled or unknown | High |
| SEC-004 | Security | High volume of failed SSH authentication logs | Medium |
| SEC-005 | Security | Automatic security updates not enabled | Medium |
| CTR-001 | Containers | Docker installed but unreachable | High |
| CTR-002 | Containers | Unhealthy/restarting containers | High |
| CTR-003 | Containers | Docker JSON logs above 100 MiB | High |
| WEB-001 | Web | Installed web server not active | High |
| WEB-002 | Web | Configured domain DNS/TLS failure or ≤14 days | High |

## Known interpretation limits

- Cloud firewalls are invisible to a local host scan, so SEC-001 may warn on a protected host.
- SSH includes and conditional `Match` blocks can make policy interpretation complex; review `sshd -T` directly.
- Authentication log counts are log entries, not unique attackers.
- A Docker container without a healthcheck cannot be classified as healthy by Docker.
- WEB-002 performs an outbound connection only when domains are explicitly configured and quick mode is off.
