---
name: spring-explore
description: >
  Exploring a Spring Boot application and building primary context: stack, module structure, domain entities, repositories, services, REST endpoints. Use for "explore project", "describe project", "what is this project", or when you need to understand the project before a task.
---

# Exploring a Spring application

Collects primary project context. If context was already collected in the current conversation — do not repeat it, use what is known.

## Step 0 — Predict involvement from the request

Without calling tools, use naming conventions, domain language, and typical Spring patterns to predict what the task involves: entities, repositories, services, controllers, other beans, non-Java files. This drives the rest of the exploration.

```
### Predicted involvement:
- Entities: Order, OrderItem, Customer
- Repositories: OrderRepository, CustomerRepository
- Services: OrderService
- Controllers: OrderController
- Files: src/main/resources/db/migration/V1__create_orders.sql, application.properties
```

## Step 1 — Goal and exploration paths

State the exploration goal in one sentence. Then choose what to look for (only what is needed):

- **Stack and versions** — `pom.xml` / `build.gradle` / `build.gradle.kts`, `application.properties|yml`.
- **Module/package structure** — the `src/main/java` tree.
- **Entities** — `@Entity` / `@Table` / `@Document`.
- **Repositories** — `extends ...Repository`.
- **Services** — `@Service`.
- **Controllers and endpoints** — `@RestController` / `@Controller`, `@RequestMapping` / `@GetMapping` / `@PostMapping` / etc.
- **Mappers** — `@Mapper` (MapStruct).
- **DTOs** — `*Dto` / `*Request` / `*Response` classes.
- **Configuration** — `@Configuration`, `@ConfigurationProperties`.

## Step 2 — Explore with ordinary tools

Use `find`, `grep`, `read`, `ls`, `bash` (read-only). Order:

1. Read the build file — stack and versions.
2. Look at the package structure.
3. Run targeted searches on the chosen paths.
4. Read only relevant files, not everything.

## Step 3 — Report

Synthesize everything into one report (only what is valuable, no noise):

```
### Exploration Report

**Stack:** Java 21 · Spring Boot 3.x · Maven
**Persistence:** JPA / JDBC / none

**Domain model:**
- Order (id, status, totalAmount) → has many OrderItem → references Product

**Repositories:**
- OrderRepository — JpaRepository, supports pagination

**Services:**
- OrderService — order creation and status transitions

**Mappers / DTOs:**
- OrderMapper (MapStruct), OrderDto, OrderItemDto

**REST API:**
- GET /orders — paginated list
- POST /orders — create order

**Notable findings:**
- SecurityConfig present — endpoints require authentication
```

## Step 4 — Implicit assumptions

Identify what the user did not say explicitly but likely expects: behavior, security/access, validation, error handling, conventions, side effects, DTO shape. List them explicitly so they can be verified or corrected.

```
### Implicit assumptions:
1. Endpoint should require authentication — all existing endpoints do.
2. Response format matches existing endpoints — camelCase JSON, no wrapper.
...
```

If there are none, say so explicitly: "implicit assumptions: none identified".
