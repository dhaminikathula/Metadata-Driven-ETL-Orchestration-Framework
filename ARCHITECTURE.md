# Architecture Documentation

## System Design

This document describes the architecture of the Metadata-Driven ETL Orchestration Framework.

### Core Components

1. **Orchestrator**: Main engine that orchestrates ETL pipelines
2. **Connectors**: Data source connection management
3. **Loaders**: Data loading and transformation logic
4. **Database**: PostgreSQL with control and audit tables

### Data Flow

```
Source Data → Connector → Loader → Destination
    ↓
Control Table → Orchestrator → Audit Table
```

### Metadata-Driven Approach

- Pipeline definitions stored in `etl_control` table
- No hardcoded pipeline logic
- Dynamic DAG generation
- Circular dependency detection
- Topological sorting for execution order

## Key Features

- **Scalability**: Containerized with Docker Compose
- **Auditability**: Complete logging in audit tables
- **Flexibility**: Add new pipelines via SQL INSERT
- **Resilience**: Error handling and recovery mechanisms
