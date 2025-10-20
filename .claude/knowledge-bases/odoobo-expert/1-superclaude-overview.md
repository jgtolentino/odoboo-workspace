# SuperClaude Framework Overview

## Mission & Architecture

SuperClaude is a unified agentic framework consolidating 30+ production-ready agents with 540x development power multiplier through:

- **Intelligent Routing**: <50ms agent selection based on context
- **Wave-Based Coordination**: 5-wave progressive enhancement (Discovery → Design → Implementation → Validation → Deployment)
- **Multi-Agent Orchestration**: Parallel and sequential agent coordination
- **Sub-Agent Delegation**: Automatic task distribution to specialized agents

## Core Components

### 1. Agent Registry

Location: `/Users/tbwa/.claude/AGENT_REGISTRY.md`

**Registered Agents** (30 total):

- **Core SuperClaude**: 11 agents (security-analyst, arbiter, code-review, quality-validator, figma-design-to-code, figma-workflow, fullstack-engineer, scout-mcp, scout-patterns, scout-expert, solutions-architect)
- **Universal Design Platform**: 11 agents (Designer, Coder, Architect, QA, PM, BIDashboard, Diagram, DataViz, ReactOptimization, CrossPlatformPublisher, UniversalExtractionLane)
- **Enterprise ERP**: odoobo-expert (Odoo development, deployment, operations)

### 2. Personas System

Location: `/Users/tbwa/.claude/PERSONAS.md`

**11 Domain-Specific Personas**:

**Technical Specialists**:

- `architect`: Systems design and long-term architecture
- `frontend`: UI/UX and user-facing development
- `backend`: Server-side and infrastructure systems
- `security`: Threat modeling and vulnerability assessment
- `performance`: Optimization and bottleneck elimination

**Process & Quality Experts**:

- `analyzer`: Root cause analysis and investigation
- `qa`: Quality assurance and testing
- `refactorer`: Code quality and technical debt management
- `devops`: Infrastructure and deployment automation

**Knowledge & Communication**:

- `mentor`: Educational guidance and knowledge transfer
- `scribe`: Professional documentation and localization

**Auto-Activation**: Multi-factor scoring (keyword 30%, context 40%, history 20%, metrics 10%)

### 3. Orchestrator

Location: `/Users/tbwa/.claude/ORCHESTRATOR.md`

**Detection Engine**:

- Resource validation (token, memory, permissions)
- Compatibility validation (flags, personas, tools)
- Risk assessment (0.0-1.0 complexity scoring)
- Intent extraction (domain + operation classification)

**Resource Thresholds**:

- Green (0-60%): Full operations
- Yellow (60-75%): Optimize, suggest --uc mode
- Orange (75-85%): Warning, defer non-critical
- Red (85-95%): Force efficiency, block intensive ops
- Critical (95%+): Emergency, essential only

**Domain Classification**:

```yaml
frontend: [UI, component, React, Vue, CSS, responsive, accessibility]
backend: [API, database, server, endpoint, authentication, performance]
infrastructure: [deploy, Docker, CI/CD, monitoring, scaling, configuration]
security: [vulnerability, authentication, encryption, audit, compliance]
documentation: [document, README, wiki, guide, manual, instructions]
enterprise_erp: [odoo, ERP, module, OCA, __manifest__, PostgreSQL, nginx]
```

**Wave System**:

- Auto-activation: complexity ≥0.7 + files >20 + operation_types >2
- Strategies: progressive, systematic, adaptive, enterprise
- Checkpoints: wave boundary gates with rollback capability

### 4. Command System

Location: `/Users/tbwa/.claude/COMMANDS.md`

**Wave-Enabled Commands** (9 total):

- `/analyze`: Multi-dimensional code and system analysis
- `/build`: Project builder with framework detection
- `/design`: Design orchestration and system architecture
- `/design-extract`: Extract design tokens from any website
- `/improve`: Evidence-based code enhancement
- `/review`: Comprehensive code review and quality analysis
- `/scan`: Security and code quality scanning
- `/task`: Long-term project management
- `/troubleshoot`: Problem investigation

**Integration**: Auto-persona activation, MCP coordination, tool orchestration

### 5. MCP Servers

Location: `/Users/tbwa/.claude/MCP.md`

**Available Servers**:

- **Context7**: Official library documentation, code examples, best practices
- **Sequential**: Multi-step problem solving, architectural analysis
- **Magic**: UI component generation, design system integration
- **Playwright**: Cross-browser E2E testing, performance monitoring

**Selection Algorithm**: Task-server affinity → performance metrics → context awareness → load distribution

### 6. Modes

Location: `/Users/tbwa/.claude/MODES.md`

**Operational Modes**:

- **Task Management**: Hierarchical task organization with persistent memory
- **Introspection**: Meta-cognitive analysis for reasoning optimization
- **Token Efficiency**: Symbol-enhanced communication (30-50% reduction)
- **Brainstorming**: Collaborative discovery mindset
- **Business Panel**: Multi-expert business analysis (9 thought leaders)
- **Deep Research**: Systematic investigation with evidence-based reasoning

## Framework Integration Points

### Agent Registration Process

1. Create agent YAML in `/Users/tbwa/.claude/agents/`
2. Define capabilities, tools, MCP preferences
3. Update `AGENT_REGISTRY.md` with entry
4. Add domain classification to `ORCHESTRATOR.md`
5. Create persona definitions in `PERSONAS.md` or separate YAML
6. Test with evaluation suite

### Orchestrator Integration

```yaml
agent:
  name: odoobo-expert
  domain: enterprise_erp + infrastructure + backend
  complexity_threshold: moderate
  wave_eligible: true
  auto_delegate: true
  personas: [odoo-developer, odoo-tester, odoo-architect, odoo-sysadmin, odoo-devops]
```

### Quality Standards

- **Visual Parity**: ≥99% pixel-perfect accuracy
- **Extraction Fidelity**: ≥95% for primary platforms
- **Cross-Platform Consistency**: ≥95% design parity
- **Performance**: React-first optimization with ≥85% retention
- **Token Efficiency**: <10K tokens per operation
- **Response Time**: P95 <5 seconds for individual agents

## Agentic Capabilities

### Multi-Agent Orchestration

- **Wave-based execution**: 5-wave collaborative workflow
- **Autonomous decision-making**: Agents operate independently
- **Persistent memory**: Cross-session learning and context retention
- **Environmental awareness**: Real-time system state perception

### Progressive Disclosure

- Skills/knowledge loaded on-demand only
- Metadata baseline: ~50 tokens per skill
- Full instructions: only when skill is needed
- 95% token savings vs. loading all upfront

## Best Practices

1. **Task-First Approach**: Understand → Plan → Execute → Validate
2. **Evidence-Based Reasoning**: All claims verifiable through testing/docs
3. **Parallel Thinking**: Maximize efficiency through intelligent batching
4. **Context Awareness**: Maintain ≥90% understanding across operations
5. **Quality Gates**: Validate before execution, verify after completion
6. **Session Lifecycle**: Initialize with /sc:load, checkpoint regularly, save before end

## Success Metrics

**Framework Performance**:

- Agent selection: <50ms
- Multi-agent coordination: <15s for complex workflows
- Cross-platform publishing: <2min for full deployment
- Token extraction: 100% design decision capture

**Quality Achievements**:

- Visual fidelity: ≥99% pixel-perfect
- Code quality: ESLint clean, 90%+ test coverage
- Accessibility: WCAG 2.1 AA compliance
- Documentation: Complete with examples

---

**Framework Version**: 4.0.8
**Last Updated**: 2025-10-20
**Total Agents**: 30
**Power Multiplier**: 540x
