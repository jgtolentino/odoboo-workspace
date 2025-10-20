# Odoobo-Expert Architecture Diagrams

Visual representations of the local-first development architecture.

---

## System Architecture Overview

```mermaid
graph TB
    subgraph "Local Development Environment"
        A[Developer Machine]

        subgraph "SuperClaude Framework (~/.claude/)"
            B[Agent Config<br/>odoobo-expert.agent.yaml]
            C[Skills Directory]
            D[Knowledge Base<br/>Local ChromaDB]
        end

        subgraph "Skills (5 Capabilities)"
            C1[PR Review<br/>Code Analysis]
            C2[Odoo RPC<br/>API Client]
            C3[NL-SQL<br/>Query Generator]
            C4[Visual Diff<br/>Screenshot Compare]
            C5[Design Tokens<br/>CSS Extractor]
        end

        subgraph "Git Worktrees (Parallel Dev)"
            E1[main<br/>odoboo-workspace]
            E2[feature/pr-review<br/>workspace-pr-review]
            E3[feature/odoo-rpc<br/>workspace-odoo-rpc]
            E4[feature/nl-sql<br/>workspace-nl-sql]
            E5[feature/visual-diff<br/>workspace-visual-diff]
        end

        F[Agent Service<br/>FastAPI + Claude]
    end

    subgraph "External Services"
        G1[GitHub API]
        G2[Odoo Instance]
        G3[PostgreSQL DB]
        G4[Web Browsers]
    end

    subgraph "Production (DO Gradient AI)"
        H[Vector Store<br/>50K+ Embeddings]
        I[RAG Pipeline<br/>Retrieval + Generation]
        J[Agent Runtime<br/>Claude 3.5 Sonnet]
    end

    A --> B
    B --> C
    C --> C1 & C2 & C3 & C4 & C5
    B --> D

    E1 --> E2 & E3 & E4 & E5
    E2 -.-> C1
    E3 -.-> C2
    E4 -.-> C3
    E5 -.-> C4

    F --> C1 & C2 & C3 & C4 & C5
    F --> D

    C1 --> G1
    C2 --> G2
    C3 --> G3
    C4 --> G4

    D -.Deploy.-> H
    H --> I
    I --> J
    F -.Deploy.-> J

    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#ffe1e1
    style D fill:#e1ffe1
    style F fill:#f0e1ff
    style H fill:#ffe1f5
    style I fill:#ffe1f5
    style J fill:#ffe1f5
```

---

## Skill Architecture

```mermaid
graph LR
    subgraph "Anthropic Skills Pattern"
        A[SKILL.md<br/>Instructions]
        B[skill.py<br/>Executable]
        C[requirements.txt<br/>Dependencies]
        D[tests/<br/>Test Suite]
        E[resources/<br/>Patterns & Schemas]
    end

    subgraph "Skill Execution"
        F[Claude Code Agent]
        G[Code Execution Tool<br/>Sandboxed Python]
        H[External APIs<br/>GitHub, Odoo, etc.]
    end

    subgraph "Quality Gates"
        I[Unit Tests<br/>pytest]
        J[Integration Tests<br/>Agent Service]
        K[Coverage Report<br/>≥80%]
    end

    A --> F
    B --> G
    C --> G
    E --> B

    F --> G
    G --> H
    G --> B

    D --> I
    I --> J
    J --> K

    style A fill:#fff4e1
    style B fill:#e1f5ff
    style G fill:#ffe1e1
    style I fill:#e1ffe1
    style K fill:#f0e1ff
```

---

## Git Worktrees Development Flow

```mermaid
graph TD
    A[Main Worktree<br/>main branch]

    subgraph "Parallel Development (Isolated)"
        B[PR Review Worktree<br/>feature/pr-review]
        C[Odoo RPC Worktree<br/>feature/odoo-rpc]
        D[NL-SQL Worktree<br/>feature/nl-sql]
        E[Visual Diff Worktree<br/>feature/visual-diff]
        F[Design Tokens Worktree<br/>feature/design-tokens]
    end

    G[Integration Testing<br/>All Skills Merged]
    H[Production Deployment<br/>DO App Platform]

    A -.Create Worktrees.-> B & C & D & E & F

    B -.Develop & Test.-> B1[Commit #1]
    C -.Develop & Test.-> C1[Commit #2]
    D -.Develop & Test.-> D1[Commit #3]
    E -.Develop & Test.-> E1[Commit #4]
    F -.Develop & Test.-> F1[Commit #5]

    B1 -.Merge.-> G
    C1 -.Merge.-> G
    D1 -.Merge.-> G
    E1 -.Merge.-> G
    F1 -.Merge.-> G

    G -.All Tests Pass.-> H

    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#fff4e1
    style D fill:#fff4e1
    style E fill:#fff4e1
    style F fill:#fff4e1
    style G fill:#e1ffe1
    style H fill:#ffe1f5
```

---

## Knowledge Base Architecture

```mermaid
graph TB
    subgraph "Data Sources (Public)"
        A1[Odoo Docs<br/>odoo.com/documentation]
        A2[OCA Guidelines<br/>github.com/OCA]
        A3[Odoo Forums<br/>odoo.com/forum]
        A4[Custom Docs<br/>Internal Patterns]
    end

    subgraph "Local Development"
        B[Document Chunking<br/>512 tokens, 50 overlap]
        C[Local Embeddings<br/>sentence-transformers]
        D[ChromaDB<br/>Vector Store]
        E[Retrieval Engine<br/>Top-K + Rerank]
    end

    subgraph "Production (DO Gradient AI)"
        F[Production Embeddings<br/>text-embedding-ada-002]
        G[DO Vector Store<br/>Managed Service]
        H[RAG Pipeline<br/>Retrieval + Generation]
    end

    subgraph "Agent Integration"
        I[Claude 3.5 Sonnet]
        J[Context Enhancement<br/>Retrieved Docs + Query]
        K[Response Generation<br/>Grounded in Docs]
    end

    A1 & A2 & A3 & A4 --> B
    B --> C
    C --> D
    D --> E

    D -.Migrate.-> F
    F --> G
    G --> H

    E -.Local Query.-> J
    H -.Production Query.-> J
    J --> I
    I --> K

    style A1 fill:#e1f5ff
    style A2 fill:#e1f5ff
    style A3 fill:#e1f5ff
    style A4 fill:#e1f5ff
    style D fill:#e1ffe1
    style G fill:#ffe1f5
    style I fill:#f0e1ff
    style K fill:#fff4e1
```

---

## Development Workflow Timeline

```mermaid
gantt
    title Odoobo-Expert Development Timeline
    dateFormat YYYY-MM-DD
    section Setup
    Environment Setup           :done, setup, 2025-10-21, 1d
    Git Worktrees Creation     :done, worktrees, 2025-10-21, 1d

    section Skills Development
    PR Review Skill            :active, pr, 2025-10-22, 7d
    Odoo RPC Skill            :odoorpc, 2025-10-29, 7d
    NL-SQL Skill              :nlsql, 2025-11-05, 7d
    Visual Diff Skill         :visual, 2025-11-12, 7d
    Design Tokens Skill       :tokens, 2025-11-19, 7d

    section Integration
    Merge All Branches        :merge, 2025-11-26, 3d
    Integration Testing       :integration, 2025-11-29, 4d

    section Knowledge Base
    Data Collection           :data, 2025-12-03, 7d
    Local Embeddings          :embed, 2025-12-10, 4d

    section Deployment
    Migrate to DO Gradient AI :deploy, 2025-12-14, 3d
    Production Testing        :prod, 2025-12-17, 4d

    section Optimization
    RAG Tuning               :optimize, 2025-12-21, 7d
```

---

## Skill Execution Flow

```mermaid
sequenceDiagram
    participant U as User
    participant A as Claude Agent
    participant S as Skill Executor
    participant K as Knowledge Base
    participant E as External API

    U->>A: /review 123 odoo/odoo
    A->>K: Query: "Odoo PR review patterns"
    K-->>A: Top 5 relevant docs
    A->>S: Execute pr-review skill
    S->>E: Fetch PR diff (GitHub API)
    E-->>S: PR patch + metadata
    S->>S: Analyze code changes
    S->>S: Detect lockfile sync
    S->>S: Scan for vulnerabilities
    S-->>A: ReviewResult
    A->>A: Format response with context
    A-->>U: PR analysis + recommendations

    Note over A,K: Knowledge base provides<br/>Odoo-specific patterns
    Note over S,E: Skill executes in<br/>sandboxed environment
```

---

## Cost Optimization Strategy

```mermaid
graph TD
    subgraph "Development Phase (Months 1-3)"
        A[Local ChromaDB<br/>$0/month]
        B[Git Worktrees<br/>$0/month]
        C[Local Testing<br/>$0/month]
        D[Total: $0/month]
    end

    subgraph "Production Phase (Month 4+)"
        E[DO Gradient AI Embeddings<br/>$2/month]
        F[DO Gradient AI Queries<br/>$1/month]
        G[DO App Platform<br/>$5/month]
        H[DO Spaces Storage<br/>$0.01/month]
        I[Total: ~$8/month]
    end

    subgraph "Scaling (10x Queries)"
        J[Embeddings: $2]
        K[Queries: $10]
        L[App Platform: $5]
        M[Total: ~$17/month]
    end

    A & B & C --> D
    E & F & G & H --> I
    J & K & L --> M

    D -.Zero-cost dev.-> I
    I -.Controlled scale.-> M

    style D fill:#e1ffe1
    style I fill:#fff4e1
    style M fill:#ffe1f5
```

---

## Skill Composition Patterns

```mermaid
graph LR
    subgraph "Sequential Execution"
        A1[PR Review] --> A2[Security Scan]
        A2 --> A3[Generate Report]
    end

    subgraph "Parallel Execution (Wave Mode)"
        B1[PR Review]
        B2[Visual Diff]
        B3[NL-SQL Analysis]
        B4[Merge Results]

        B1 & B2 & B3 --> B4
    end

    subgraph "Conditional Execution"
        C1[PR Review]
        C2{Security Issues?}
        C3[Visual Diff]
        C4[Block Merge]

        C1 --> C2
        C2 -->|Yes| C4
        C2 -->|No| C3
    end

    style A1 fill:#e1f5ff
    style B1 fill:#fff4e1
    style B2 fill:#fff4e1
    style B3 fill:#fff4e1
    style C1 fill:#ffe1e1
    style C4 fill:#f0e1ff
```

---

## Deployment Architecture

```mermaid
graph TB
    subgraph "Local Development"
        A[Skills in ~/.claude/]
        B[Knowledge Base<br/>ChromaDB]
        C[Agent Service<br/>localhost:8001]
    end

    subgraph "CI/CD Pipeline"
        D[GitHub Actions]
        E[Run Tests<br/>pytest + coverage]
        F[Build Docker Image]
        G[Push to Registry]
    end

    subgraph "DigitalOcean Production"
        H[App Platform<br/>agent-service]
        I[Gradient AI<br/>Vector Store]
        J[Spaces<br/>Asset Storage]
    end

    subgraph "Monitoring"
        K[Prometheus<br/>Metrics]
        L[Grafana<br/>Dashboards]
        M[Alerts<br/>Slack/Email]
    end

    A -.Commit & Push.-> D
    B -.Export Embeddings.-> I

    D --> E
    E --> F
    F --> G
    G --> H

    H --> K
    K --> L
    L --> M

    C -.Local Test.-> E
    H -.Production.-> I & J

    style C fill:#e1f5ff
    style H fill:#ffe1f5
    style I fill:#ffe1f5
    style L fill:#e1ffe1
```

---

## Performance Targets

```mermaid
graph TD
    subgraph "Development Metrics"
        A[Iteration Time<br/>Goal: <2 min]
        B[Test Coverage<br/>Goal: ≥80%]
        C[Local Build Time<br/>Goal: <30s]
    end

    subgraph "Production SLAs"
        D[Skill Execution<br/>P95: <5s]
        E[KB Retrieval<br/>P95: <200ms]
        F[End-to-End<br/>P95: <10s]
        G[Uptime<br/>Goal: 99.9%]
    end

    subgraph "Cost Constraints"
        H[Development<br/>$0/month]
        I[Production<br/><$10/month]
        J[Cost per Query<br/><$0.001]
    end

    A -.Fast feedback.-> D
    B -.Quality gate.-> G
    D -.Low latency.-> F
    E -.Fast retrieval.-> F
    H -.Zero cost dev.-> I
    I -.Cost efficient.-> J

    style A fill:#e1ffe1
    style D fill:#fff4e1
    style F fill:#ffe1e1
    style H fill:#e1f5ff
    style I fill:#f0e1ff
```

---

## Security Architecture

```mermaid
graph TB
    subgraph "Authentication Layer"
        A[Environment Variables]
        B[GitHub Token]
        C[Anthropic API Key]
        D[Odoo Credentials]
    end

    subgraph "Skill Execution Sandbox"
        E[Python Sandbox<br/>Limited Resources]
        F[Network Whitelist<br/>GitHub, Odoo, etc.]
        G[Memory Limit<br/>512MB]
        H[Timeout<br/>30 seconds]
    end

    subgraph "Data Protection"
        I[Secrets in Env Only]
        J[No Hardcoded Tokens]
        K[RLS on Supabase]
        L[HTTPS Only]
    end

    A --> B & C & D
    B & C & D --> E

    E --> F & G & H

    F -.Restricted access.-> I
    I --> J & K & L

    style A fill:#ffe1e1
    style E fill:#fff4e1
    style I fill:#e1ffe1
```

---

## Notes

**Legend**:

- **Blue boxes**: Configuration/Setup
- **Yellow boxes**: Active processes
- **Green boxes**: Success states
- **Red boxes**: Error/Block states
- **Pink boxes**: Production environment

**Diagram Tools**:

- Rendered with Mermaid.js
- View in GitHub, VS Code, or https://mermaid.live/

**Updates**:

- Architecture finalized: 2025-10-21
- Next review: After Phase 1 completion (Week 2)
