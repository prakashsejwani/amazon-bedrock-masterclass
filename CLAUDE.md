# CLAUDE.md Guidelines

## Developer Workflows & Commands

### Backend (Ruby on Rails 8)
- **Directory**: `code/rails/`
- **Install Dependencies**: `bundle install`
- **Run Tests**: `bundle exec rails test`
- **Run Server**: `bundle exec rails server -p 3001`
- **Console**: `bundle exec rails console`

### Frontend (Next.js 16 Client & Docs Website)
- **Directories**: `code/nextjs/` or `docs/`
- **Install Dependencies**: `npm install`
- **Run Dev Server**: `npm run dev`
- **Build App**: `npm run build`
- **Lint**: `npm run lint`

### Linters & Validators
- **Markdown Lint**: `npx markdownlint-cli "lessons/**/*.md"`
- **Link Check**: `docker run --rm -v "$PWD":/lychee lycheeverse/lychee "/lychee/lessons/**/*.md"` or local `lychee` command

---

## Coding Style & Standards

### Ruby on Rails 8
- Target Ruby 3.4 syntax features.
- Keep controllers thin; extract business logic into services under `app/services/` (e.g., `app/services/bedrock_service.rb`).
- Use standard Rails conventions, avoid complex metaprogramming.
- Use explicit error handling for Bedrock runtime errors (`Aws::BedrockRuntime::Errors::ServiceError`).

### Frontend (TypeScript / Next.js)
- Next.js App Router structure.
- TypeScript in strict mode. Ensure all types are explicitly declared (no `any`).
- Use Tailwind CSS for utility styling.
- Use `shadcn/ui` components for common UI patterns.
- Ensure all interactive elements have unique and descriptive IDs.

### Technical Writing & Documentation
- Avoid filler words or conversational introductions. Go straight to technical facts.
- Include ASCII or Mermaid diagrams to visualize concepts.
- Include a quiz and typical interview questions at the end of each lesson.
- Always write complete code examples. Do not use placeholders (e.g., `// TODO: implement this`).

---

## Git Workflow

1. Create a feature branch named `lesson-00X-description` (e.g., `lesson-001-introduction`).
2. Implement the lesson markdown, assets, and lab code.
3. Validate locally (run tests, verify Next.js compiles, run linting scripts).
4. Commit using conventional commits (`feat: ...`, `docs: ...`, `fix: ...`, `refactor: ...`).
5. Open a Pull Request to `main`.
6. Merge ONLY after local verification and CI checks pass.
7. Delete the feature branch locally and remotely.
