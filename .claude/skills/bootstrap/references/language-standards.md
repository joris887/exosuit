# Language Standards Reference

Reference loaded by `/bootstrap` when populating `docs/reference/CODING_STANDARDS.md` language sections. Maps each detected language to its authoritative base standard and key conventions.

## Base Standards by Language

For each detected language, reference the base standard in the `### Base Standard` subsection. Document ONLY project-specific deviations from the base — the base standard itself provides comprehensive coverage.

| Language | Base Standard | Reference |
|----------|--------------|-----------|
| Python | PEP 8 + Google Python Style Guide | peps.python.org/pep-0008, google.github.io/styleguide/pyguide.html |
| TypeScript | Airbnb JavaScript Style Guide (TS variant) | github.com/airbnb/javascript |
| JavaScript | Airbnb JavaScript Style Guide | github.com/airbnb/javascript |
| Go | Effective Go + Go Code Review Comments | go.dev/doc/effective_go, go.dev/wiki/CodeReviewComments |
| Rust | Rust API Design Guidelines | rust-lang.github.io/api-guidelines |
| Ruby | Ruby Style Guide (community) | rubystyle.guide |
| Java | Google Java Style Guide | google.github.io/styleguide/javaguide.html |
| C# | .NET Framework Design Guidelines | learn.microsoft.com/dotnet/standard/design-guidelines |
| Swift | Swift API Design Guidelines | swift.org/documentation/api-design-guidelines |
| Kotlin | Kotlin Coding Conventions | kotlinlang.org/docs/coding-conventions.html |
| PHP | PSR-12: Extended Coding Style | php-fig.org/psr/psr-12 |
| Dart | Effective Dart | dart.dev/effective-dart |
| C/C++ | Google C++ Style Guide | google.github.io/styleguide/cppguide.html |

## Naming Conventions by Language

Fill the language section's naming table with these conventions:

| Language | Variables | Functions | Classes/Types | Constants | Files |
|----------|-----------|-----------|--------------|-----------|-------|
| Python | snake_case | snake_case | PascalCase | UPPER_SNAKE | snake_case.py |
| TypeScript | camelCase | camelCase | PascalCase | UPPER_SNAKE | kebab-case.ts or camelCase.ts |
| JavaScript | camelCase | camelCase | PascalCase | UPPER_SNAKE | kebab-case.js or camelCase.js |
| Go | camelCase (unexported), PascalCase (exported) | same | PascalCase | PascalCase or UPPER_SNAKE | snake_case.go |
| Rust | snake_case | snake_case | PascalCase | UPPER_SNAKE | snake_case.rs |
| Ruby | snake_case | snake_case | PascalCase | UPPER_SNAKE | snake_case.rb |
| Java | camelCase | camelCase | PascalCase | UPPER_SNAKE | PascalCase.java |
| C# | camelCase (local), PascalCase (public) | PascalCase | PascalCase | PascalCase | PascalCase.cs |
| Swift | camelCase | camelCase | PascalCase | camelCase | PascalCase.swift |
| Kotlin | camelCase | camelCase | PascalCase | UPPER_SNAKE | PascalCase.kt |
| PHP | camelCase | camelCase | PascalCase | UPPER_SNAKE | PascalCase.php |
| Dart | camelCase | camelCase | PascalCase | camelCase | snake_case.dart |
| C/C++ | snake_case | snake_case | PascalCase | UPPER_SNAKE | snake_case.c/.h |

## Error Handling Patterns by Language

Use these as the canonical error pattern in the `### Error Handling` or `### Patterns We Use` subsection:

| Language | Pattern | Example |
|----------|---------|---------|
| Python | Typed exceptions with context | `raise ValueError(f"Invalid email: {email!r}")` |
| TypeScript | Typed errors or Result pattern | `throw new AppError("NOT_FOUND", "User not found", { userId })` |
| Go | Wrap errors with `%w` | `return fmt.Errorf("fetch user %d: %w", id, err)` |
| Rust | `Result<T, E>` with `?` operator | `let user = db.find(id).context("fetch user")?;` |
| Java | Checked for recoverable, unchecked for bugs | `throw new UserNotFoundException("User " + id + " not found")` |
| C# | Exceptions with inner exception chain | `throw new AppException("Failed to fetch user", ex)` |
| Ruby | Custom error classes inheriting StandardError | `raise UserNotFoundError, "User #{id} not found"` |
| Swift | `throws` + typed errors | `throw AppError.notFound("User \(id)")` |
| Kotlin | Sealed classes for domain errors | `sealed class UserError { data class NotFound(val id: Int) : UserError() }` |
| PHP | Typed exceptions | `throw new UserNotFoundException("User {$id} not found")` |

## Version Pin Extraction

When populating the `### Version Pins` subsection, extract versions from these sources:

| Language | Lockfile / Config | Extract |
|----------|------------------|---------|
| Python | `pyproject.toml`, `setup.cfg`, `Pipfile` | `python_requires`, key deps in `[project.dependencies]` |
| TypeScript/JS | `package.json` | `engines.node`, key deps in `dependencies` |
| Go | `go.mod` | `go` directive, key `require` entries |
| Rust | `Cargo.toml` | `edition`, `rust-version`, key `[dependencies]` |
| Java | `pom.xml`, `build.gradle` | `java.version`, key `<dependency>` entries |
| C# | `*.csproj` | `<TargetFramework>`, key `<PackageReference>` entries |
| Ruby | `Gemfile`, `.ruby-version` | Ruby version, key gems |
| Swift | `Package.swift` | Swift tools version, key `.package()` entries |
| PHP | `composer.json` | `require.php`, key packages |

**Key libraries = the 3-5 most important dependencies** (framework, ORM, HTTP client, test runner). Don't list every dependency — only the ones where version-specific API differences could cause hallucinated code.

## Common AI Anti-Patterns by Language

When populating `### Patterns to Avoid`, consider these language-specific AI pitfalls:

| Language | Common AI Anti-Pattern | Better Alternative |
|----------|----------------------|-------------------|
| Python | `import *` or mixing sync/async | Explicit imports; pick sync OR async per module |
| TypeScript | Using `any` to bypass type errors | Define proper types or use `unknown` with type guards |
| Go | Ignoring returned errors (`_, err :=` then not checking) | Always check: `if err != nil { return fmt.Errorf(...) }` |
| Rust | Excessive `.unwrap()` / `.expect()` | Use `?` operator with proper error types |
| Java | Catching `Exception` instead of specific types | Catch the narrowest exception type |
| C# | Using `async void` (except event handlers) | Use `async Task` for all async methods |
| Ruby | Monkey-patching core classes | Use composition or refinements |
| Swift | Force unwrapping optionals (`!`) | Use `guard let` or `if let` |
