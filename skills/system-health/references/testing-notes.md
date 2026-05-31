# Testing Methodology — Fresh Install Simulation

Before publishing a skill, simulate a fresh install to verify the first-run experience.

## Procedure

1. **Clean environment**
   ```bash
   rm -rf ~/.hermes/skills/devops/<skill-name>
   rm -f ~/.hermes/logs/.system-health-state ~/.hermes/logs/system-health.log
   ```

2. **Re-install** (copy back or install from source)

3. **Verify first-run config prompts** — the `metadata.hermes.config` should fire automatically

4. **Run all scripts** — check output format, no errors

5. **Check syntax**
   ```bash
   bash -n scripts/health_check.sh && echo "OK"
   ```

6. **Validate SKILL.md frontmatter**
   ```python
   import yaml, re
   c = open('SKILL.md').read()
   m = re.search(r'\n---\s*\n', c[3:])
   fm = yaml.safe_load(c[3:m.start()+3])
   assert len(fm['description']) <= 1024
   assert len(c) <= 100000
   assert fm['name'] == fm['name'].lower()
   ```

## What We Found During Testing

| Issue | Fix |
|-------|-----|
| API key grep pattern had trailing space | Simplified grep pattern |
| Aider --version outputs help text | Use pip3 show instead |
| Profile key showing "?" | Use explicit status labels: 未配置/正常 |
| Cron check hardcoded specific job names | Detect scheduler process, not job names |
