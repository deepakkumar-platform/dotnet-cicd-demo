# .NET Microservice CI/CD Demo (GitHub Actions)

A small, working copy of a real-world .NET microservice pipeline, showing 5 improvements:

| # | Improvement | Where |
|---|---|---|
| 1 | Secret scanning (Gitleaks) | `cicd.yml` → job `security-scan` |
| 2 | Vulnerable NuGet package check | `cicd.yml` → job `build` |
| 3 | SonarQube + Quality Gate (always on for prod) | `cicd.yml` → job `build` |
| 4 | Results on the run summary + Teams notification | every job + `notify-teams` |
| 5 | Pull request checks | `pr-checks.yml` |

New checks **warn** on `qa` and **block** on `prod`.

## Layout

```
src/Demo.Api/                    .NET 8 minimal API (/health, /api/price)
tests/Demo.Api.Tests/            xUnit tests
.github/config/                  deploy-mapping.<env>.json (paths, port, runner label per service)
.github/scripts/deploy-linux.sh  stop → backup → copy (keeps appsettings) → start
.github/workflows/cicd.yml       manual deploy pipeline
.github/workflows/pr-checks.yml  runs on every PR
```

## Pipeline flow

```
resolve (ubuntu) → security-scan (ubuntu) → build (windows-latest) → deploy (self-hosted) → notify-teams
                   #1 Gitleaks              #2 vuln packages          health check          #4 Teams
                                            tests + #4 summary
                                            #3 Sonar gate
```

## Demo branches (problems planted on purpose)

| Branch | Planted problem | What to show |
|---|---|---|
| `demo/leaked-secret-and-vulnerable-package` | Password in `appsettings.json` + `Newtonsoft.Json 12.0.1` (High CVE) | Deploy to **qa** → warnings, still deploys. Deploy to **prod** → blocked |
| `demo/failing-test` | A broken discount rule | PR shows ❌. Deploy is blocked |

---

## Run it

### 1. Start the self-hosted runner (deploy target = your Linux machine)
Only needed for the deploy job. Use `SkipDeploy = true` to skip it.

```bash
# One-time setup: repo → Settings → Actions → Runners → New self-hosted runner (Linux x64),
# then use the commands GitHub shows, adding the label:
./config.sh --url https://github.com/<owner>/<repo> --token <TOKEN> --labels demo-runner --unattended

# Each demo session:
cd ~/actions-runner && ./run.sh      # Ctrl+C to stop
```

The machine needs the .NET 8 runtime. The deploy script uses `~/.dotnet/dotnet` or `dotnet` on PATH.

> ⚠️ This is a **public** repo. Only `workflow_dispatch` (people with write access) uses the self-hosted runner.
> PR checks run on GitHub-hosted runners only. Stop the runner when you're not demoing.

### 2. Run the pipeline
Actions → **Demo Microservice CI/CD** → Run workflow → pick environment / branch.
Open the run → the **Summary** page shows secret scan, packages, tests, Sonar and deployment results.

After deploy: `curl http://localhost:5080/health` (qa) or `:5090` (prod).

### 3. Optional: SonarCloud (free for public repos)
1. sonarcloud.io → sign in with GitHub → import this repo.
2. Project → Administration → Analysis Method → turn **off** Automatic Analysis.
3. Repo → Settings → Secrets and variables → Actions:
   - Secret `SONAR_TOKEN` (My Account → Security → Generate token)
   - Variables `SONAR_ORGANIZATION` and `SONAR_PROJECT_KEY` (shown on the SonarCloud project page)

Without these, the Sonar step shows "⚠️ Skipped" in the summary.

### 4. Optional: Teams
Teams channel → Workflows → *Post to a channel when a webhook request is received* → copy the URL →
add it as secret `TEAMS_WEBHOOK_URL`. Without it, the summary shows the message that *would* be sent.

---

## Differences from a Windows/IIS setup

| Real pipeline | This demo |
|---|---|
| `deploy-windows.ps1`: stop app pool → backup → copy → restart IIS | `deploy-linux.sh`: stop process → backup → copy → start `dotnet Demo.Api.dll` |
| Self-hosted **Windows** runner | Self-hosted **Linux** runner |
| On-prem SonarQube | SonarCloud |

Everything else is the same idea: manual trigger with dropdowns, mapping JSON per environment, build on
`windows-latest`, artifact handed from build to deploy, tests block the deploy.
