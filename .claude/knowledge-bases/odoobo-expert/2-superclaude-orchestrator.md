# SuperClaude Orchestrator & Wave System

## Orchestrator Architecture

### Detection Engine

**Pre-Operation Validation**:

```yaml
resource_validation:
  - token_usage_prediction
  - memory_requirements_estimation
  - file_system_permissions
  - mcp_server_availability

compatibility_validation:
  - flag_combination_conflicts
  - persona_command_compatibility
  - tool_availability
  - project_structure_requirements

risk_assessment:
  - complexity_scoring: 0.0-1.0
  - failure_probability: historical_patterns
  - resource_exhaustion_likelihood
  - cascading_failure_potential
```

**Resource Management Thresholds**:

- **Green Zone** (0-60%): Full operations, predictive monitoring active
- **Yellow Zone** (60-75%): Resource optimization, caching, suggest --uc mode
- **Orange Zone** (75-85%): Warning alerts, defer non-critical operations
- **Red Zone** (85-95%): Force efficiency modes, block resource-intensive operations
- **Critical Zone** (95%+): Emergency protocols, essential operations only

### Pattern Recognition

**Complexity Detection**:

```yaml
simple:
  indicators: [single file, basic CRUD, straightforward queries, <3 steps]
  token_budget: 5K
  time_estimate: <5min

moderate:
  indicators: [multi-file, analysis, refactoring, 3-10 steps]
  token_budget: 15K
  time_estimate: 5-30min

complex:
  indicators: [system-wide, architectural, performance optimization, >10 steps]
  token_budget: 30K+
  time_estimate: >30min
```

**Domain Identification**:

```yaml
frontend:
  keywords: [UI, component, React, Vue, CSS, responsive, accessibility]
  file_patterns: ['*.jsx', '*.tsx', '*.vue', '*.css', '*.scss']
  operations: [create, style, optimize, test]

backend:
  keywords: [API, database, server, endpoint, authentication, performance]
  file_patterns: ['*.js', '*.ts', '*.py', '*.go', 'controllers/*', 'models/*']
  operations: [implement, optimize, secure, scale]

infrastructure:
  keywords: [deploy, Docker, CI/CD, monitoring, scaling, configuration]
  file_patterns: ['Dockerfile', '*.yml', '*.yaml', '.github/*', 'terraform/*']
  operations: [setup, configure, automate, monitor]

enterprise_erp:
  keywords: [odoo, ERP, module, OCA, __manifest__, PostgreSQL, nginx, docker-compose]
  file_patterns: ['**/__manifest__.py', '**/models/*.py', '**/views/*.xml', 'docker-compose.yml']
  operations: [scaffold, deploy, migrate, test, backup, optimize]
```

**Operation Type Classification**:

```yaml
analysis:
  verbs: [analyze, review, explain, understand, investigate, troubleshoot]
  outputs: [insights, recommendations, reports]
  tools: [Grep, Read, Sequential]

creation:
  verbs: [create, build, implement, generate, design]
  outputs: [new files, features, components]
  tools: [Write, Magic, Context7]

modification:
  verbs: [update, refactor, improve, optimize, fix]
  outputs: [edited files, improvements]
  tools: [Edit, MultiEdit, Sequential]

wave_operations:
  verbs: [comprehensively, systematically, thoroughly, progressively, iteratively]
  modifiers: [improve, optimize, refactor, modernize, enhance, audit, transform]
  outputs: [comprehensive improvements, systematic enhancements, progressive transformations]
  tools: [Sequential, Task, Read, Edit, MultiEdit, Context7]
  patterns: [review-plan-implement-validate, assess-design-execute-verify]
```

### Routing Intelligence

**Master Routing Table**:
| Pattern | Complexity | Domain | Auto-Activates | Confidence |
|---------|------------|---------|----------------|------------|
| "analyze architecture" | complex | infrastructure | architect, --ultrathink, Sequential | 95% |
| "create component" | simple | frontend | frontend, Magic, --uc | 90% |
| "fix bug" | moderate | any | analyzer, --think, Sequential | 85% |
| "optimize performance" | complex | backend | performance, --think-hard, Playwright | 90% |
| "security audit" | complex | security | security, --ultrathink, Sequential | 95% |
| "comprehensive audit" | complex | multi | --multi-agent --parallel-focus | 95% |
| "improve large system" | complex | any | --wave-mode --adaptive-waves | 90% |

**Decision Trees**:

1. Parse user request for keywords and patterns
2. Match against domain/operation matrices
3. Score complexity based on scope and steps
4. Evaluate wave opportunity scoring
5. Estimate resource requirements
6. Generate routing recommendation (traditional vs wave mode)

## Wave Orchestration Engine

### Wave System Overview

Multi-stage command execution with compound intelligence. Auto-activates when:

- Complexity ≥0.7 AND
- Files >20 OR
- Operation types >2

**Wave Control**:

```yaml
wave_activation:
  automatic: 'complexity >= 0.7'
  explicit: '--wave-mode, --force-waves'
  override: '--single-wave, --wave-dry-run'

wave_strategies:
  progressive: 'Incremental enhancement'
  systematic: 'Methodical analysis'
  adaptive: 'Dynamic configuration'
  enterprise: 'Large-scale operations'
```

### Wave-Enabled Commands (9 total)

**Tier 1**: `/analyze`, `/improve`, `/build`, `/scan`, `/review`
**Tier 2**: `/design`, `/troubleshoot`, `/task`, `/design-extract`

### Wave Workflow Pattern

```
Wave 1: Discovery & Analysis
  - Context gathering
  - Requirement extraction
  - Dependency mapping
  - Resource assessment
  Output: Comprehensive understanding

Wave 2: Design & Planning
  - Strategy development
  - Component architecture
  - Workflow design
  - Risk mitigation planning
  Output: Detailed implementation plan

Wave 3: Implementation
  - Code generation
  - Module creation
  - Integration development
  - Progressive enhancement
  Output: Working implementation

Wave 4: Validation & Testing
  - Quality assurance
  - Security scanning
  - Performance testing
  - Visual parity validation
  Output: Validated solution

Wave 5: Deployment & Monitoring
  - Production deployment
  - Health monitoring
  - Performance tracking
  - Continuous optimization
  Output: Production-ready system
```

### Wave Opportunity Scoring

**Scoring Factors**:

```python
complexity_score = (
    high_complexity * 0.4 +  # >0.8 complexity
    operation_types * 0.3 +   # >2 operation types
    critical_quality * 0.2 +  # security/production
    file_count * 0.1          # >50 files
)

wave_recommended = complexity_score >= 0.7
```

**Strategy Selection**:

- **Security Focus**: wave_validation
- **Performance Focus**: progressive_waves
- **Critical Operations**: wave_validation
- **Multiple Operations**: adaptive_waves
- **Enterprise Scale**: enterprise_waves
- **Default**: systematic_waves

### Sub-Agent Delegation

**Delegation Scoring**:

```yaml
delegation_triggers:
  directory_threshold: >7 directories → --delegate --parallel-dirs
  file_threshold: >50 files AND complexity >0.6 → --delegate --sub-agents
  multi_domain: >3 domains → --delegate --parallel-focus
  complex_analysis: complexity >0.8 AND scope=comprehensive → --delegate --focus-agents
  token_optimization: estimated_tokens >20K → --delegate --aggregate-results
```

**Sub-Agent Specialization**:

```yaml
quality_agent:
  persona: qa
  focus: [complexity, maintainability]
  tools: [Read, Grep, Sequential]

security_agent:
  persona: security
  focus: [vulnerabilities, compliance]
  tools: [Grep, Sequential, Context7]

performance_agent:
  persona: performance
  focus: [bottlenecks, optimization]
  tools: [Read, Sequential, Playwright]

architecture_agent:
  persona: architect
  focus: [patterns, structure]
  tools: [Read, Sequential, Context7]
```

**Delegation Routing**:
| Operation | Complexity | Auto-Delegates | Performance Gain |
|-----------|------------|----------------|------------------|
| `/load @monorepo/` | moderate | --delegate --parallel-dirs | 65% |
| `/analyze --comprehensive` | high | --multi-agent --parallel-focus | 70% |
| Comprehensive system improvement | high | --wave-mode --progressive-waves | 80% |
| Enterprise security audit | high | --wave-mode --wave-validation | 85% |
| Large-scale refactoring | high | --wave-mode --systematic-waves | 75% |

## Tool Selection Matrix

**Base Tool Selection**:

- **Search**: Grep (specific patterns) or Agent (open-ended)
- **Understanding**: Sequential (complexity >0.7) or Read (simple)
- **Documentation**: Context7
- **UI**: Magic
- **Testing**: Playwright

**Wave Integration**:

- Wave Score >0.7: Add Sequential for coordination, auto-enable wave strategies
- Delegation Score >0.6: Add Task tool, auto-enable delegation flags

**Auto-Flag Assignment**:

```yaml
directory_count_gt_7: --delegate --parallel-dirs
focus_areas_gt_2: --multi-agent --parallel-focus
high_complexity_critical: --wave-mode --wave-validation
multiple_operation_types: --wave-mode --adaptive-waves
```

## Performance Optimization

**Token Management**:

- Detection Engine: 1-2K tokens
- Decision Trees: 500-1K tokens
- MCP Coordination: Variable based on servers

**Operation Batching**:

- Tool coordination: Parallel when no dependencies
- Context sharing: Reuse analysis results
- Cache strategy: Store successful routing patterns
- Task delegation: Intelligent sub-agent spawning
- Resource distribution: Dynamic token allocation

**Target Performance**:

- Detection: <100ms
- Routing: <50ms
- Wave coordination: <15s for complex workflows
- Sub-agent spawning: <2s per agent

---

**Version**: 4.0.8
**Last Updated**: 2025-10-20
**Orchestrator Response Time**: <50ms average
**Wave Coordination**: 5-wave progressive enhancement
**Delegation Capability**: 15 specialized sub-agents
