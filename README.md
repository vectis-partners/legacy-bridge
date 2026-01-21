# Legacy Data Bridge (Vectis-Ops)

**A zero-dependency exfiltration and integration kit for air-gapped or legacy Windows environments (Server 2008 / Win7+).**

### The Problem
Modern APIs (REST/GraphQL) do not exist in legacy enterprise environments. Critical business data is often trapped in:
* On-premise SQL Server 2005/2008 instances
* Flat-file exports on local file systems
* Proprietary "Black Box" ERPs with no external connectivity

### The Solution
This toolkit provides a "Living off the Land" approach to extraction. It uses native PowerShell (v2.0 compatible) to detect, capture, and securely bridge data to modern cloud infrastructure via TLS 1.2, without requiring software installation or complex firewall changes.

### Components
* **Bridge (PowerShell):** ~4KB agent. Runs in user-space. Watches for report generation/file IO. Handles retry logic and HTTPS transport.
* **Receiver (Python/Flask):** Lightweight C2 endpoint that accepts, sanitizes, and structures the incoming legacy data for modern consumption.

### Usage
*Intended for Forward Deployed Engineering & Implementation teams dealing with high-friction on-premise integrations.*
