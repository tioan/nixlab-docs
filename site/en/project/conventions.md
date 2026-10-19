# Conventions

- One git worktree per topic (`.worktrees/<topic>`), removed and its branch deleted when done. Tofu state always stays in the main checkout.
- Plan first, implement after approval.
- Subdomains by function (`rezepte`, not `mealie`).
- New web services on grammi use PostgreSQL instead of SQLite.
- Dual stack wherever possible.
- Code comments explain the *why*, including the mistakes that led to a decision, with a date.
- Code comments, commit messages and changelogs in English; the project documentation exists in German and English.
- The docs site loads nothing from third parties: the fonts and glightbox ship with the site (`docs/assets.nix`) instead of coming from Google Fonts or unpkg.com. Why: GDPR, and private docs that work without internet access.
