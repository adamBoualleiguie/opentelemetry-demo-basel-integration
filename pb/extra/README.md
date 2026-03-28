# Optional proto outputs (future)

Planned targets for **BZ-032** (Python `py_proto_library`), **BZ-034** (Java `java_proto_library`), **BZ-035** (C++ `cc_proto_library`), and **BZ-033** (TypeScript via `ts_proto` / rules_js) were scoped out of default **M1** CI to keep the module graph small.

They can be added here in **M1.1** or **M2** by extending `MODULE.bazel` with `rules_java`, `rules_python`, and (for TS) Node rules, then adding a `BUILD.bazel` next to this README.
