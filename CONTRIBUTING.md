# Contributing to Fukurō

Thanks for your interest in contributing to **Fukurō**!

Please see our comprehensive engineering guide in [DOCUMENT.md](DOCUMENT.md) for full details on:
- Environment setup (JDK, Android Studio, SDK, Gradle)
- Architecture overview & DI graph
- Compose and Live Edit conventions
- Testing workflows (Waydroid, emulator, physical phone)
- Code formatting and Spotless verification
- Commit conventions and pull request submission checklist

---

## Quick Reference

### Issues & Discussions
- If you're interested in working on an issue, please comment on it on GitHub so others know it is being addressed.
- You do not need formal permission to submit pull requests.

### Pull Requests
1. Branch from `master`.
2. Follow [Conventional Commits](https://www.conventionalcommits.org/).
3. Run `./scripts/check.sh` to ensure code formatting passes Spotless checks.
4. Run `./gradlew test` to ensure all unit tests pass.
5. Submit your PR against the `master` branch.

### Forks & Attribution
Fukurō is open-source software under the [Apache 2.0 License](LICENSE). Please respect all upstream attributions and licensing requirements.