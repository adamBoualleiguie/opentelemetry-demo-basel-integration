# Quote Service

The Quote Service calculates the shipping costs,
based on the number of items to be shipped.

It is a PHP based service, using a combination of automatic and manual instrumentation.

## Docker Build

To build the quote service, run the following from root directory
of opentelemetry-demo

```sh
docker compose build quote
```

## Run the service

Execute the below command to run the service.

```sh
docker compose up quote
```

In order to get traffic into the service you have to deploy
the whole opentelemetry-demo.

Please follow the root README to do so.

## Development

To build and run the quote service locally:

```sh
docker build src/quote --target base -t quote
cd src/quote
docker run --rm -it -v $(pwd):/var/www -e QUOTE_PORT=8999 -p "8999:8999" quote
```

Then, send some curl requests:

```sh
curl --location 'http://localhost:8999/getquote' \
--header 'Content-Type: application/json' \
--data '{"numberOfItems":3}'
```

## Bazel (build, test, OCI)

This service is wired for **Bazel** (**BZ-095**): host **PHP** and **Composer** (align with **`src/quote/Dockerfile`**: **PHP 8.4** on **Alpine 3.22** in the runtime image; **`composer install`** flags mirror the **Dockerfile** vendor stage). **`composer install`** hits **Packagist** — build and test targets use **`requires-network`**.

| Target | Role |
|--------|------|
| **`//src/quote:quote_publish`** | Runs **`composer install`** into a declared directory (**`//tools/bazel:composer_install.bzl`** **`composer_install`**). |
| **`//src/quote:quote_image`** / **`quote_load`** | **`rules_oci`** image on **`php:8.4-cli-alpine3.22`** → **`otel/demo-quote:bazel`**. |
| **`//src/quote:quote_composer_smoke_test`** | **`sh_test`** — **`composer install`** + **`php -r` `require vendor/autoload.php`** (**`tags = ["unit", "requires-network"]`**, **`size = "enormous"`**). |

```bash
# Requires `php` and `composer` on PATH (e.g. shivammathur/setup-php in CI).
bazel build //src/quote:quote_publish //src/quote:quote_image --config=ci
bazel test //src/quote:quote_composer_smoke_test --config=ci
bazel test //src/quote:quote_composer_smoke_test --config=unit
# optional: bazel run //src/quote:quote_load && docker run --rm -e QUOTE_PORT=8090 -p 8090:8090 otel/demo-quote:bazel
```

**Why not `rules_php`?** There is no single BCR **`rules_php`** graph that replaces **Composer** + **Packagist** for this Slim / React HTTP app. The maintainers use a small **`composer_install`** rule (same idea as **`dotnet_publish`** / **`mix_release`**).

**Parity notes:** **`src/quote/Dockerfile`** installs **PHP extensions** (**`opentelemetry`**, **`protobuf`**, …) via **`install-php-extensions`**. The Bazel **OCI** base is stock **`php:8.4-cli-alpine`** without that step — see **`docs/bazel/oci-policy.md`** (**PHP (`quote`)**). **`docker compose build quote`** remains the path for full Dockerfile parity.

There is no **`composer.lock`** in-tree; **`composer install`** resolves from **`composer.json`** only (same as the **Dockerfile** vendor stage).
