# Contributing to Stash

Thanks for your interest. Contributions are welcome for both the smart contracts (`contracts/`) and the web app (`web/`).

---

## Workflow

**Never push directly to `main` or `dev`.** All changes come in through pull requests.

```
main       ← production-ready; merged from dev after review
 └── dev   ← integration branch; all PRs target this
      └── your-feature-branch
```

### Setup (one time)

After cloning, activate the pre-push hook that blocks accidental pushes to `main` or `dev`:

```bash
git config core.hooksPath .githooks
```

That's it. The hook runs automatically before every `git push`.

### Step by step

1. **Fork** the repository to your own GitHub account.
2. **Clone** your fork and run `git config core.hooksPath .githooks`.
3. **Create a branch** off `dev` — not `main`, not `dev` itself:
   ```bash
   git checkout dev
   git pull upstream dev
   git checkout -b feat/flexible-vault-permit
   ```
4. **Make your changes.** Keep each branch focused on one thing.
5. **Commit** using the pattern below.
6. **Push** to your fork and open a **PR targeting `dev`**.
7. After review and CI passes, a maintainer merges to `dev`.
8. Periodically, `dev` is merged into `main` for a release.

---

## Branch naming

```
feat/<short-description>      new feature
fix/<short-description>       bug fix
chore/<short-description>     tooling, config, deps
docs/<short-description>      documentation only
test/<short-description>      tests only
refactor/<short-description>  no behaviour change
```

Examples: `feat/fixed-vault-permit`, `fix/verify-chainid-param`, `docs/architecture-diagram`

---

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary in present tense>

[optional body — explain the why, not the what]

[optional footer — breaking changes, closes #issue]
```

**Types:** `feat` · `fix` · `chore` · `docs` · `test` · `refactor` · `style`  
**Scopes:** `contracts` · `web` · `ci` · `scripts` · `deps`

**Examples:**

```
feat(contracts): add depositWithPermit to FlexibleVault

fix(contracts): append ?chainid to Etherscan V2 verifier URL

docs(contracts): add ARCHITECTURE.md with deployment addresses

test(contracts): add invariant for FixedVault balance coverage

chore(web): upgrade wagmi to v2.13

ci: pin foundry-toolchain to v1
```

Keep the summary line under 72 characters. Use the body when the reason for the change isn't obvious from the diff.

---

## Pull requests

- **Target branch:** `dev` — PRs to `main` will be closed.
- **Title:** follow the same `type(scope): summary` format as commits.
- **Description:** what changed and why; link any related issue.
- **Keep PRs small** — one logical change per PR is easier to review.
- Make sure CI is green before requesting review (format, build, tests).

---

## Contracts — local checks before pushing

```bash
cd contracts
forge fmt          # format (CI runs forge fmt --check)
forge build        # must compile cleanly
forge test -vvv    # all tests must pass
```

## Web — local checks before pushing

```bash
cd web
npm run lint       # eslint must pass
npm run build      # production build must succeed
```
