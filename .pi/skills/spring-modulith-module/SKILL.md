---
name: spring-modulith-module
description: >
  Use when creating or reorganizing modules in a Spring Modulith project (DDD + hexagonal).
  Covers package structure, @ApplicationModule, @NamedInterface, module configuration via
  @Bean, jMolecules aggregate annotations, cross-module dependencies only through API
  packages, and ApplicationModules.verify() tests. Triggers when you need to create a new
  module, restrict dependencies between modules, or see packages shaped like
  api/application/domain/infrastructure with @ApplicationModule / @NamedInterface annotations.
---

# Spring Modulith: DDD module

A module is a top-level package under the application root package. Inside it — strict layers.
Cross-module dependencies go ONLY through the public API package (`api/`).

## Module structure

```
src/main/java/<base-package>/
└── <module>/                            ← module
    ├── package-info.java                ← @ApplicationModule(allowedDependencies = {...})
    ├── api/                             ← public contract (visible to other modules)
    │   └── <feature>/                   ← @NamedInterface("<feature>")
    │       ├── package-info.java
    │       ├── <UseCase>.java           ← use case interface (in port)
    │       ├── <UseCase>Command.java    ← input data (record)
    │       ├── <UseCase>Result.java     ← output data (record/DTO)
    │       ├── <Entity>Id.java          ← typed ID (available to other modules)
    │       └── <Enum>.java
    ├── application/                     ← use case implementations + module config
    │   ├── usecase/                     ← <Name>UseCase (implements the api interface)
    │   └── config/                      ← <Module>ModuleConfig (@Configuration + @Bean)
    ├── domain/                          ← pure domain (jMolecules aggregates, repository ports)
    │   └── <aggregate>/                 ← Aggregate, AggregateRepository, value objects
    └── infrastructure/                  ← adapters (persistence, external services, web/bot)
        └── persistence/                 ← InMemory/Jpa repositories (implement the domain port)
```

## 1. Declaring a module — package-info.java

`package-info.java` at the module package root. Annotations must be fully qualified
(`package-info` has no imports):

```java
/**
 * Student bounded context.
 * Manages student profiles, progress tracking, and word acquisition history.
 */
@org.springframework.modulith.ApplicationModule(
        allowedDependencies = {"dictionary :: dictionary",
                "dictionary :: word",
                "shared :: shared"}
)
package com.example.student;
```

- `allowedDependencies` — the allowlist of what the module may depend on.
- Element format: `"<module> :: <named-interface>"` or just `"<module>"`.
- An empty list `{}` means the module depends on nothing (for example, `shared`).

## 2. Public API — @NamedInterface

Each public subpackage inside `api/` is declared as a named interface:

```java
@org.springframework.modulith.NamedInterface("student")
package com.example.student.api.student;
```

Other modules reference it as `"student :: student"`. This narrows the dependency
to a specific API package instead of the whole module.

## 3. Use case — interface in api/, implementation in application/

```java
// api/student/CreateStudent.java — in port, visible to other modules
public interface CreateStudent {
    StudentId execute(CreateStudentCommand command);
}
```

```java
// application/usecase/CreateStudentUseCase.java — plain class, NO @Service
@RequiredArgsConstructor
@Slf4j
public class CreateStudentUseCase implements CreateStudent {

    private final StudentRepository studentRepository;   // port from domain

    @Override
    public StudentId execute(CreateStudentCommand cmd) {
        var name = Objects.requireNonNull(cmd.name(), "Name must not be null");
        if (name.isBlank()) {
            throw new IllegalArgumentException("Name must not be blank");
        }
        var student = Student.create(StudentId.generate(), cmd.dictionaryId(), cmd.name(), cmd.level());
        student = studentRepository.save(student);
        log.info("Student '{}' created", cmd.name());
        return student.getId();
    }
}
```

Rule: use cases are **plain classes** (not `@Service`/`@Component`), wired explicitly
through `@Bean` in the module config (see below). This gives an explicit dependency graph.

## 4. Module config — @Configuration + @Bean

```java
@Configuration
public class StudentModuleConfig {

    @Bean
    CreateStudent createStudent(StudentRepository repository) {
        return new CreateStudentUseCase(repository);
    }

    @Bean
    StudentQuery studentQuery(StudentRepository studentRepository,
            FindWords findWords,            // port from ANOTHER module (dictionary.api)
            FindActiveLesson findActiveLesson) {
        return new StudentQueryService(studentRepository, findWords, findActiveLesson);
    }
}
```

## 5. Domain — jMolecules annotations and typed IDs

```java
@Getter
@org.jmolecules.ddd.annotation.AggregateRoot
public class Student {

    @org.jmolecules.ddd.annotation.Identity
    private StudentId id;

    @org.jmolecules.ddd.annotation.Association
    private DictionaryId dictionaryId;   // reference to an aggregate of ANOTHER module — by ID only

    private String name;
    private CefrLevel level;

    private Student() {}                 // private constructor

    public static Student create(StudentId id, DictionaryId dictionaryId, String name, CefrLevel level) {
        Objects.requireNonNull(id, "StudentId must not be null");
        Objects.requireNonNull(dictionaryId, "DictionaryId must not be null");
        Objects.requireNonNull(name, "Name must not be null");
        Objects.requireNonNull(level, "Level must not be null");
        var student = new Student();
        student.id = id;
        student.dictionaryId = dictionaryId;
        student.name = name;
        student.level = level;
        return student;
    }

    public void changeLevel(CefrLevel level) {
        this.level = Objects.requireNonNull(level, "Level must not be null");
    }
}
```

- `@AggregateRoot` / `@Identity` / `@Association` come from `org.jmolecules.ddd.annotation`.
- Aggregates reference aggregates of other modules only by ID (`@Association`).
- Typed IDs (`StudentId`, `DictionaryId`) live in `api/`, because neighbors need them.

## 6. Repository — port in domain, adapter in infrastructure

```java
// domain/student/StudentRepository.java — out port (pure interface)
public interface StudentRepository {
    Student save(Student student);
    Optional<Student> findById(StudentId id);
    boolean existsByNameInIds(Set<StudentId> ids, String name);
}
```

```java
// infrastructure/persistence/InMemoryStudentRepository.java — adapter
@Repository
public class InMemoryStudentRepository implements StudentRepository {

    private final Map<StudentId, Student> store = new ConcurrentHashMap<>();

    @Override
    public Student save(Student student) {
        store.put(student.getId(), student);
        return student;
    }
    // ...
}
```

The domain knows nothing about Spring/JPA/storage — only the port.

## 7. Cross-module communication — only through api

- Importing another module's `application/`, `domain/`, or `infrastructure/` is forbidden.
- Only `api/<feature>/` of another module (its named interface) may be imported.
- The module config pulls in other modules' ports (`FindWords` from `dictionary.api.dictionary`)
  and passes them to its own use cases.
- Events between modules go through `@ApplicationModuleListener` (Spring Modulith).

## 8. Modularity tests

```java
class ModuleVerificationTest {

    @Test
    void verifyModularity() {
        // Checks: no cycles, no access to another module's non-public packages,
        // no allowedDependencies violations.
        ApplicationModules.of(MyApplication.class).verify();
    }
}

class ModuleDocumentationTest {

    @Test
    void generateComponentDiagram() throws Exception {
        var modules = ApplicationModules.of(MyApplication.class);
        new Documenter(modules).writeDocumentation();   // generates the module diagram
    }
}
```

## 9. Dependencies (pom.xml)

```xml
<dependency>
    <groupId>org.springframework.modulith</groupId>
    <artifactId>spring-modulith-starter-core</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.modulith</groupId>
    <artifactId>spring-modulith-starter-test</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.jmolecules</groupId>
    <artifactId>jmolecules-ddd</artifactId>
</dependency>
<!-- + BOMs: spring-modulith-bom, jmolecules-bom -->
```

## Gotchas

- Do not put `@Service`/`@Component` on use cases — wire them through `@Bean` in the module config.
- Do not import another module's `domain/` or `infrastructure/` — only `api/`; otherwise `verify()` fails.
- In `package-info.java`, write annotations fully qualified (`@org.springframework.modulith.ApplicationModule`); imports do not work there.
- Keep `allowedDependencies` minimal: list concrete `"module :: interface"` entries, not the whole module.
- Aggregates of other modules — only by ID (`@Association`), no direct object references.
- IDs and DTOs/commands live in `api/`, not `domain/` — neighboring modules need them.
- `@Transactional` — in the application layer (use case), not in the domain.
- Do not forget `ModuleVerificationTest` — it is the only mechanical guard of module boundaries.
- Pin the Spring Boot, Modulith, jMolecules, and Java versions to your project's actual stack.
