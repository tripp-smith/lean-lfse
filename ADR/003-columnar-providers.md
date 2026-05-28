# ADR 003: Columnar Providers

Market data providers wrap `lean-columnar` APIs for Parquet, mmap Parquet, and
Arrow IPC. CSV-like parsing remains as a small deterministic fixture path.
