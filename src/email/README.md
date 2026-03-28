# Email Service

The Email service "sends" an email to the customer with their order details by
rendering it as a log message. It expects a JSON payload like:

```json
{
  "email": "some.address@website.com",
  "order": "<serialized order protobuf>"
}
```

## Local Build

We use `bundler` to manage dependencies. To get started, simply `bundle install`.

## Running locally

You may run this service locally with `bundle exec ruby email_server.rb`.

## Docker Build

From the repository root (paths match **`EMAIL_DOCKERFILE`** in **`.env`**):

```bash
docker build -f src/email/Dockerfile .
```

## Bazel (build, test, OCI)

Hermetic Ruby is from **`rules_ruby`** (portable MRI **3.4.8**, same as **`.ruby-version`**). Gems are installed by **`ruby.bundle_fetch`** into the external repo **`@email_bundle`** (from **`Gemfile` / `Gemfile.lock`**). The lockfile **`PLATFORMS`** are **`x86_64-linux`** and **`aarch64-linux`** (glibc) so **`bundle install`** inside Bazel can resolve **`grpc`** / native gems for Linux CI; **`src/email/Dockerfile`** (Alpine) still runs **`bundle install`** and remains a supported path.

```bash
bazel build //src/email:email //src/email:email_image --config=ci
bazel test //src/email:email_gems_smoke_test --config=ci
bazel test //src/email:email_gems_smoke_test --config=unit
# optional: bazel run //src/email:email_load && docker image ls | grep otel/demo-email
```

- **`//src/email:email`** — **`rb_binary`** (**`email_server.rb`** + **`views/`**).
- **`//src/email:email_image`** / **`email_load`** — **`rules_oci`** on **`docker.io/library/ruby:3.4.8-slim-bookworm`** (digest in **`MODULE.bazel`** as **`ruby_348_slim_bookworm`**), **`WORKDIR`** **`/email_server`**, **`6060/tcp`**, same entry shape as Docker (**`bundle exec ruby email_server.rb`**). The Bazel image uses **Debian slim** (glibc) so it matches gems built by portable Ruby; the official Compose image stays **Alpine** (musl).
