# SQLHC — SQL Server Health-Check Data Collector

> A one-shot, config-driven collector that gathers a **complete SQL Server + Windows
> health-check snapshot** — ~56 diagnostic T-SQL queries, Perfmon counters, OS/driver/
> hardware inventory, and event logs — then packages everything into a single, encrypted
> ZIP ready to hand off for analysis.

<p align="left">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Windows-0078D6">
  <img alt="Language" src="https://img.shields.io/badge/language-VB.NET-5391FE">
  <img alt="Target" src="https://img.shields.io/badge/target-SQL%20Server-CC2927">
  <img alt="Scripts" src="https://img.shields.io/badge/HC%20scripts-~56-success">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue">
</p>

---

## Table of Contents

- [What it does](#what-it-does)
- [Why use it](#why-use-it)
- [How it works](#how-it-works)
- [What gets collected](#what-gets-collected)
- [The health-check script library](#the-health-check-script-library)
- [Requirements](#requirements)
- [Configuration (`SQLHC.ini`)](#configuration-sqlhcini)
- [Quick start](#quick-start)
- [Output](#output)
- [Extending the collector](#extending-the-collector)
- [Repository layout](#repository-layout)
- [Building from source](#building-from-source)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Credits](#credits)
- [License](#license)

---

## What it does

Diagnosing a sick SQL Server means collecting a lot of evidence from a lot of places —
configuration, memory, waits, top queries, blocking/deadlocks, file layout, indexes, tempdb,
disk I/O, backups, VLFs, integrity, security — **plus** the Windows side: performance
counters, hardware/driver inventory, patches, network setup, memory dumps, and event logs.
Doing that by hand is slow and inconsistent.

**SQLHC automates the entire capture in a single run.** You drop the executable + a small
`SQLHC.ini` onto the box (or run it remotely against a target), launch it, and it:

1. Runs a library of **~56 categorized T-SQL health-check queries** against the target
   instance, exporting each result to CSV.
2. Captures a **Windows Performance Monitor** trace (SQL Server + IIS + OS counters) via
   `logman`.
3. Inventories the **OS, hardware, drivers, patches, network, memory dumps, and event logs**.
4. Bundles everything into **`SQLHC_output.zip`** (password-protected) for analysis.

---

## Why use it

- **Comprehensive** — one run captures SQL *and* OS evidence that normally takes dozens of
  manual steps.
- **Consistent & repeatable** — every server gets the same battery of checks, so results are
  comparable across a fleet and over time.
- **Config-driven** — target server, auth, customer/engagement metadata, and scan cycles all
  live in a simple `SQLHC.ini`; no recompilation needed.
- **Script-extensible** — the T-SQL checks are just `.sql` files in a `SCRIPTS/` folder;
  drop in a new file and it runs automatically on the next pass (no code changes).
- **Portable output** — results are plain **CSV** (RFC 4180-compliant) plus standard Windows
  diagnostic files, wrapped in a single ZIP that's easy to transfer and open anywhere.
- **Analysis-ready** — pairs naturally with Perfmon, the
  [PAL tool](https://github.com/clinthuffman/PAL), and LLM-assisted root-cause analysis.

---

## How it works

```
  SQLHC.ini                         SQLHC.exe (VB.NET)                         OUTPUT\ ─┐
  ────────────         ┌───────────────────────────────────────────┐                  │
  Server / Auth  ──▶   │ 1. Read config, build connection string    │                  │
  Customer meta        │ 2. Generate SQL_IIS_HC.xml, logman import   │                  │
  ScanCycles           │ 3. logman start  (Perfmon capture begins)   │                  │
                       │ 4. For each SCRIPTS\*.sql → run → *.csv      │─── CSV per check │
                       │ 5. OS/HW/driver/patch/network/dump inventory │─── *.txt/*.xml   │
                       │ 6. Event logs (System + Application)         │─── *.nfo / logs  │
                       │ 7. logman stop + delete                      │                  │
                       │ 8. Zip OUTPUT → encrypted SQLHC_output.zip   │◀─────────────────┘
                       └───────────────────────────────────────────┘
                                          │
                                          ▼
                              SQLHC_output.zip  →  hand off for analysis
```

The program (`MainModule.vb`) connects to the target with **ADO.NET** (`System.Data.SqlClient`),
runs each query with a generous **30-minute command timeout**, and writes every result set to a
UTF-8 CSV via a built-in **RFC 4180** writer. Windows data is gathered by shelling out to native
tools (`logman`, `msinfo32`, `wmic`, `driverquery`, `systeminfo`, `ipconfig`, `netsh`,
`wevtutil`). Finally it compresses the `OUTPUT\` folder and nests it inside a password-protected
ZIP.

---

## What gets collected

**SQL Server (via the `SCRIPTS\*.sql` library)** — see the [script library](#the-health-check-script-library) below.

**Windows Performance Monitor** (`SQL_IIS_HC.xml`, imported as the `SQLIISHC` collector)
- Processor / Processor Performance
- PhysicalDisk (idle %, queue lengths, sec/read & sec/write latency, bytes/sec)
- Memory, System, Process
- SQL Server counter groups
- IIS / web stack: Active Server Pages, ASP.NET, .NET CLR Memory & Exceptions, Web Service

**OS / hardware / environment inventory**
- `msinfo32` system report (`.nfo`)
- `wmic` — CPU cores/logical processors, disk partition alignment, installed hotfixes (QFE)
- `driverquery` — installed drivers
- `systeminfo` + `net statistics server` — build/uptime
- `ipconfig /all`, `netsh interface …` — network configuration & TCP global settings
- Memory dump discovery/collection (`memory.dmp`, `minidump\*`)
- Event logs — System & Application, in **both text and XML** (last 30,000 events), plus a
  targeted crash-dump (EventID 1001) extract

---

## The health-check script library

The `SCRIPTS/` folder contains **~56 numbered T-SQL diagnostic scripts**, grouped by topic.
Numeric prefixes control ordering; files suffixed `R` are typically "runtime/current-state"
checks. Each script's result set is exported to its own `<name>.sql.csv`.

| Group | Area | Example checks |
|-------|------|----------------|
| **002** | Instance configuration | Active trace flags, non-default `sp_configure`, pending config changes, visible schedulers |
| **003** | Memory | Memory pressure, buffer-pool usage, ad-hoc plan bloat, Virtual Address Space (VAS) & modules |
| **004** | Current load & ring buffers | Current requests, elapsed load, connectivity & exception ring buffers |
| **005** | Top resource consumers | DB load rank by CPU, Top queries by CPU / duration / disk / plan recompilation |
| **006** | Concurrency | Deadlocks, blocking chains, deadlock log (trace flag 1222) |
| **007** | Databases & files | Enumerate DBs, data/log file placement (+ summary), large auto-growth events |
| **008** | Indexes | Missing indexes (with CREATE statements), unused indexes, table fragmentation |
| **009** | Statistics | Latest statistics-update timestamps |
| **010** | TempDB | File count, default size, disk-vs-memory, active tempdb processes |
| **011** | Disk I/O | I/O wait per database / per mount point, I/O stalls, suspect pages |
| **012** | Backups | Last backup date, backup location, backup history |
| **014** | Wait statistics | Wait-type %, current & time-boxed wait analysis |
| **015** | Parallelism | CXPACKET / MAXDOP / cost-threshold parallelism checks |
| **016** | Integrity & log health | VLF counts (2008/2012/active), last `DBCC CHECKDB`, ghost records |
| **020** | Security | Failed-login history, authentication mode |

> Every script ships with a standard **"non-production use / AS-IS, no warranty"** header.
> Because the collector simply enumerates `SCRIPTS\*.sql`, you can add, remove, or edit checks
> without touching the program.

---

## Requirements

- **Windows** with the built-in `logman`, `msinfo32`, `wmic`, `driverquery`, `systeminfo`,
  `netsh`, and `wevtutil` utilities.
- **.NET Framework** (the tool is a VB.NET console app; it also uses `Ionic.Zip`/DotNetZip for
  the encrypted output ZIP).
- **Network/driver access to the target SQL Server instance**, and a login with permission to
  read the DMVs/queries used by the scripts (sysadmin or equivalent diagnostic rights
  recommended).
- **Administrator privileges** on the collecting machine — `logman`, event-log export, and
  dump collection require elevation.
- Enough **free disk space** for the Perfmon trace, event-log exports, and the output ZIP.

---

## Configuration (`SQLHC.ini`)

On first run, if `SQLHC.ini` is missing, SQLHC **auto-creates a default** (local default
instance, Windows auth). Edit it to point at your target:

```ini
[Customer]
CustomerID=10000001
CustomerName=Contoso Ltd
OrderNumber=SRQ0000001

[Target]
Server=localhost          ; SQL Server host (or host\instance)
Instance=Default
Auth=Windows              ; "Windows" (Trusted) or "SQL"
User=sa                   ; used only when Auth=SQL
Password=password         ; used only when Auth=SQL
ScanCycles=2

[Settings]
Debug=Off
```

- **`Auth=Windows`** → a Trusted (integrated) connection to `master`.
- **`Auth=SQL`** → SQL authentication using `User` / `Password`.
- `Customer*` / `OrderNumber` tag the run for a specific engagement/support ticket.

---

## Quick start

```bat
:: 1) Put SQLHC.exe + the SCRIPTS\ folder in a working directory with free disk space
::    (e.g. C:\SQLHC). Keep SCRIPTS\ next to the EXE.
cd /d C:\SQLHC

:: 2) First run creates a default SQLHC.ini — edit it to point at your target instance
SQLHC.exe        :: (creates SQLHC.ini if missing)
notepad SQLHC.ini

:: 3) Run the full collection (from an ELEVATED prompt)
SQLHC.exe

:: 4) Collect the result and send it for analysis
::    → SQLHC_output.zip
```

The run is **largely unattended** but takes several minutes — it deliberately waits while the
Perfmon trace captures a load window and while the SQL scripts and OS inventory complete.

---

## Output

Everything lands in a working `OUTPUT\` folder during the run, then gets packaged:

| Artifact | Contents |
|----------|----------|
| `*.sql.csv` | One CSV per health-check script (RFC 4180, UTF-8) |
| `*.blg` | Perfmon binary performance log (SQL + IIS + OS counters) |
| `msinfo32.nfo` | Full system information report |
| `wmiccpucores.txt`, `wmicdiskalignment.txt`, `kblistinstalled.txt` | CPU, disk alignment, installed hotfixes |
| `driverquery.txt`, `systeminfo.txt`, `netstatssvr.txt` | Drivers, system info, uptime |
| `netipconfigall.txt`, `netsh*…txt` | Network & TCP configuration |
| `memorydmp.txt`, `meminidump.txt`, `*.dmp` | Memory-dump discovery/collection |
| `evtsys.txt/.xml`, `evtapps.txt/.xml`, `evtsys001001.txt` | System/Application event logs + crash-dump events |
| **`SQLHC_output.zip`** | ✅ **The final, password-protected deliverable** containing all of the above |

After zipping, SQLHC cleans up the temporary `OUTPUT\` folder and the intermediate XML.

---

## Extending the collector

The T-SQL checks are **data, not code** — to add a check:

1. Create a new file in `SCRIPTS/`, following the existing naming convention
   `NNN[L]-Area-Description.sql` (the numeric prefix sets run order).
2. Make it a single result-set `SELECT` (the collector exports whatever the query returns to
   one CSV).
3. That's it — the next run enumerates `SCRIPTS\*.sql` and executes it automatically.

> ⚠️ Only `.sql` files in `SCRIPTS\` are picked up. Keep non-query helper files out of that
> folder, and make sure each script is a runnable batch (no SQL*Plus/`sqlcmd`-only directives).

---

## Repository layout

```
SQLHC/
├── MainModule.vb       # VB.NET console app: config, orchestration, CSV export, zipping
├── SCRIPTS/            # ~56 numbered T-SQL health-check scripts (the check library)
│   ├── 002A-SQL-Active-Trace-Flags.sql
│   ├── 005AR-Query-TOPCPU.sql
│   ├── 014CR-Waittypes-Percentage-Timed.sql
│   └── … (see the script-library table above)
├── README.md
├── LICENSE             # MIT
└── .vs/                # Visual Studio solution state (not needed to run)
```

---

## Building from source

- Open the project in **Visual Studio** (the `.vs/` state targets VS 2017 / v15).
- It's a **VB.NET console application** targeting the .NET Framework.
- Add a reference to **DotNetZip (`Ionic.Zip`)** for the encrypted output archive.
- Build to produce `SQLHC.exe`, then ship it alongside the `SCRIPTS\` folder.

> Historically the project's tooling was distributed together with other "RDI tools"; this
> repo contains the health-check collector and its script library.

---

## Security notes

- **`SQLHC.ini` can contain SQL credentials in plaintext** (when `Auth=SQL`). Protect the file,
  prefer **Windows/Trusted authentication**, and remove the INI after a run.
- The output ZIP is **password-protected**, but treat its contents as sensitive — it includes
  configuration, event logs, and potentially memory-dump references from the server.
- Run only against systems you are **authorized** to diagnose; the tool reads broadly from
  system DMVs and the Windows event logs.
- Review each `SCRIPTS\*.sql` before use in sensitive environments — they are provided
  **"AS-IS", for non-production use, with no warranty** (per each script's header).

---

## Troubleshooting

- **"Configuration file is missing…"** — expected on first run; SQLHC writes a default
  `SQLHC.ini`. Edit it to point at your target and run again.
- **CSV is empty / "Got an error"** — the query failed on that instance (permissions or a
  version-specific DMV). Script errors are caught per-file so the rest of the run continues;
  check the console output for the message.
- **No `.blg` / Perfmon step fails** — ensure you're running **elevated**; `logman` needs
  admin rights. A leftover `SQLIISHC` collector can be removed with `logman delete SQLIISHC`.
- **Login/connection failures** — verify `Server`, `Auth`, and (for SQL auth) `User`/`Password`
  in the INI, and that the account can reach the instance and read the diagnostic DMVs.
- **Version-specific scripts** — some checks are version-targeted (e.g. the VLF scripts for
  SQL 2008 vs 2012); non-applicable ones may simply return nothing on other versions.

---

## FAQ

**Does it change anything on the server?**
It's read-only against SQL Server (diagnostic `SELECT`s from DMVs). On the collecting machine it
temporarily creates/starts/stops/deletes a Perfmon collector and writes files to `OUTPUT\`.

**Which SQL Server versions are supported?**
It targets on-prem SQL Server broadly; several scripts include version-specific variants
(e.g. VLF 2008/2012). Newer builds generally work for the common DMV-based checks.

**Can I run it remotely?**
Yes — point `Server` at a remote `host\instance`. Note that some OS-level inventory
(`msinfo32`, event logs, dumps) reflects the **machine SQLHC runs on**, so for full OS evidence
run it on the SQL host itself.

**Why CSV?**
CSV is universal — open the results in Excel, import to a database, or feed them to an analysis
pipeline/LLM. The writer is RFC 4180-compliant, so quoting/escaping is handled correctly.

**Where does the name come from?**
**SQLHC** = **SQL** **H**ealth-**C**heck — part of a family of "RDI" database tooling.

---

## Credits

- Authored by **Arief Nugraha** (see commit history), originating from internal database tooling
  at PT. Reksa Data Indonesia.
- Related tooling: the [RPDCLI](https://github.com/syuaip/rpdcli) performance-data collector and
  the [PAL tool](https://github.com/clinthuffman/PAL) for analyzing the resulting `.blg` logs.

---

## License

Licensed under the **MIT License** — see [`LICENSE`](LICENSE). Note the SQL scripts additionally
carry an explicit **"AS-IS, non-production, no warranty"** disclaimer in their headers.

---

<sub>SQLHC — capture a full SQL Server + Windows health-check in one run, zipped and ready to analyze.</sub>
