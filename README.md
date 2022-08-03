# Werkstatt K8S Lab Deployment

# k8s-tf-lab

Basic Terraform modules for Werkstatt projects

## Core functions for integrating with solutions using Terraform

- Basic deployment and core functions
- External configuration in custom json file

## Dependencies

- [ ] **Basic Libraries**
- [ ] **Cryptodome**
- [ ] **Terraform**

Install dependencies, see [Setup documentation](docs/SETUP.md) for more details.

```bash
Linux
python3 -m pip install wheel requests urllib3 pyCryptodome pandas json2html jsonpath-ng jsonpath_rw_ext --user
```

```bash
Windows
python -m pip install wheel requests urllib3 pyCryptodome pandas json2html jsonpath-ng jsonpath_rw_ext

```

## Solutions leveraging the base tools

| Solution          | API | Python |
| :---------------- | :-: | :----: |
| Werkstatt Tools   | ⬜  |   ✅   |
| Shell Scripts     | ⬜  |   ⬜   |
| Terraform Scripts | ⬜  |   ⬜   |

- ✅ — Supported
- 🔶 — Partial support
- 🚧 — Under development
- ⬜ - N/A ️

**ToDO**:

- [x] Initial Core Development
- [ ] Build OS scripts
- [ ] Build Terraform scripts

**Info**:

- Log files are being written to [home]/werkstatt/logs
- Werkstatt main log file is [home]/werkstatt/logs/integrations.log
- Configuration files are in [home]/werkstatt/configs
- Example files are in [project]/samples

## Documentation of Modules
