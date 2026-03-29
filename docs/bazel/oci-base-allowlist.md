# OCI base image allowlist (BZ-720 / M5)

**`MODULE.bazel`** declares container bases with **`oci.pull`** (digest-pinned). To avoid unreviewed **`oci.pull`** additions, this fork keeps a **checked allowlist** and a small verifier.

## Files

| File | Role |
|------|------|
| **`tools/bazel/policy/oci_base_allowlist.txt`** | One **`name =`** per line (repository rule name, not image URL). |
| **`tools/bazel/policy/check_oci_allowlist.py`** | Fails if **`MODULE.bazel`** has an **`oci.pull`** name not in the file, or if the file lists names that no longer exist. |
| **`//tools/bazel/policy:oci_allowlist_test`** | **`sh_test`** (tag **`unit`**) wrapping the script for **`bazel test`**. |

**`tools/bazel/ci/ci_full.sh`** and **`ci_fast.sh`** run the Python check before Bazel build/test.

## Process for a new base image

1. Add **`oci.pull`** in **`MODULE.bazel`** (with digest and platforms).  
2. Add the **`name =`** string to **`oci_base_allowlist.txt`** (sorted or grouped as you prefer — keep one name per line).  
3. Update **`docs/bazel/oci-policy.md`** if the matrix or rationale changes.  
4. Run **`make bazel-check-oci-allowlist`** or **`bazel test //tools/bazel/policy:oci_allowlist_test`**.

## Relation to BZ-122

**`docs/bazel/oci-policy.md`** remains the **human** matrix (service ↔ base). This document is the **machine-enforced** list of allowed **`oci.pull`** rule names.
