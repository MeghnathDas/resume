# Meghnath Das — Resume

LaTeX source for the professional resume of **Meghnath Das**, Senior .NET / Full Stack Engineer.

---

## Tech Stack Highlights

**Languages & Frameworks:** C#, .NET Core, ASP.NET Web API, Angular, TypeScript, JavaScript  
**Databases & Cloud:** MS SQL Server, Cosmos DB, MongoDB, Azure (Functions, Service Bus, DevOps), AWS  
**Tools & Practices:** REST API, CI/CD, Git, Agile/Scrum, SOLID, DI, Unit Testing

---

## Building Locally

### Generate LaTeX from JSON

The resume content is managed in `profile.datasource.json`. To update the `.tex` file:

```bash
python3 scripts/generate_resume.py
```

### Prerequisites

- [Python 3](https://www.python.org/) (required for generating the LaTeX source from JSON)
- [TeX Live](https://www.tug.org/texlive/) or any XeLaTeX distribution with `xelatex` available in `PATH`

### Build

```bash
mkdir -p dist && xelatex -output-directory=dist resume.tex
```

The compiled PDF is output to `dist/resume.pdf`. Intermediate files (`.log`, `.aux`, etc.) are cleaned up automatically by the VS Code build task.

### VS Code Task

Open the project in VS Code and run:

- **Build:** **Terminal → Run Build Task** (`⌘⇧B`) → runs `Build Resume PDF` (compile + cleanup).
- **Setup:** **Terminal → Run Task…** → `Setup Environment` to validate your local setup and (optionally) install/update TeX Live packages via `tlmgr`.

`Setup Environment` runs `scripts/setup_environment.sh` and will:

- Check `python3` is available on your `PATH`
- Check `xelatex` is available on your `PATH`
- Check `tlmgr` (and warn if missing)
- Optionally run `sudo tlmgr update --self` and `sudo tlmgr update --all`
- Verify required packages (e.g. `enumitem`, `geometry`, `fontspec`, `microtype`) and optionally install missing ones

---

## Project Structure

```
.
├── resume.tex                  # Main LaTeX source
├── config/
│   ├── minimal-resume.sty      # Custom resume style
│   ├── minimal-resume-config.tex
│   └── custom-command.tex
├── dist/
│   └── resume.pdf              # Compiled output (auto-generated)
├── scripts/
│   └── setup_environment.sh   # Environment setup helper
└── .github/workflows/
    └── compile-resume.yml      # CI: auto-compiles and uploads the resume PDF as a build artifact
```

---

## CI / CD

A GitHub Actions workflow (`.github/workflows/compile-resume.yml`) automatically compiles the resume and commits the updated `dist/resume.pdf` on every push to `main`.

---

## Editor

![](https://meghnathdas.github.io/public/images/MD_Logo_138X138.png)

http://meghnathdas.github.io/
