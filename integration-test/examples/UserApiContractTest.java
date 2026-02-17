package com.example.integration.api;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

/**
 * User API 契约测试示例
 *
 * 演示如何使用 RestAssured 进行 API 契约测试
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@DisplayName("User API 契约测试")
class UserApiContractTest {

    @LocalServerPort
    private int port;

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
            .withDatabaseName("test_db")
            .withUsername("test_user")
            .withPassword("test_pass");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @BeforeEach
    void setUp() {
        RestAssured.port = port;
        RestAssured.basePath = "/api";
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
    }

    // ==================== GET /api/users/{id} ====================

    @Test
    @DisplayName("GET /api/users/{id} - 正常返回符合契约")
    void getById_ExistingUser_ReturnsValidContract() {
        // 先创建一个用户
        Long userId = given()
            .body("""
                {
                    "username": "contract_test_user",
                    "email": "contract@example.com",
                    "password": "Password123!"
                }
                """)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .statusCode(201)
            .extract()
            .path("id");

        // Act & Assert
        given()
            .pathParam("id", userId)
            .accept(ContentType.JSON)
        .when()
            .get("/users/{id}")
        .then()
            .statusCode(200)
            .contentType(ContentType.JSON)
            .body("id", equalTo(userId.intValue()))
            .body("username", notNullValue())
            .body("email", notNullValue())
            .body("createdAt", notNullValue());
    }

    @Test
    @DisplayName("GET /api/users/{id} - 不存在返回 404")
    void getById_NonExistingUser_Returns404() {
        given()
            .pathParam("id", 99999)
        .when()
            .get("/users/{id}")
        .then()
            .statusCode(404)
            .body("errorCode", equalTo("USER_NOT_FOUND"))
            .body("message", containsString("not found"));
    }

    // ==================== GET /api/users ====================

    @Test
    @DisplayName("GET /api/users - 分页查询返回正确结构")
    void list_WithPagination_ReturnsValidStructure() {
        given()
            .queryParam("page", 0)
            .queryParam("size", 10)
            .accept(ContentType.JSON)
        .when()
            .get("/users")
        .then()
            .statusCode(200)
            .contentType(ContentType.JSON)
            .body("content", isA(list()))
            .body("pageable.pageNumber", equalTo(0))
            .body("pageable.pageSize", equalTo(10))
            .body("totalElements", greaterThanOrEqualTo(0))
            .body("totalPages", greaterThanOrEqualTo(0));
    }

    // ==================== POST /api/users ====================

    @Test
    @DisplayName("POST /api/users - 成功创建返回 201")
    void create_ValidRequest_Returns201() {
        String requestBody = """
            {
                "username": "newuser",
                "email": "newuser@example.com",
                "password": "SecurePass123!"
            }
            """;

        given()
            .body(requestBody)
            .contentType(ContentType.JSON)
            .accept(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .statusCode(201)
            .body("id", notNullValue())
            .body("username", equalTo("newuser"))
            .body("email", equalTo("newuser@example.com"))
            .header("Location", containsString("/api/users/"));
    }

    @Test
    @DisplayName("POST /api/users - 请求参数校验失败返回 400")
    void create_InvalidRequest_Returns400() {
        String requestBody = """
            {
                "username": "",
                "email": "invalid-email"
            }
            """;

        given()
            .body(requestBody)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .statusCode(400)
            .body("validationErrors", hasSize(greaterThan(0)))
            .body("message", containsString("validation"));
    }

    @Test
    @DisplayName("POST /api/users - 重复用户名返回 409")
    void create_DuplicateUsername_Returns409() {
        String requestBody = """
            {
                "username": "duplicate_api_user",
                "email": "first@example.com",
                "password": "Password123!"
            }
            """;

        // 第一次创建
        given()
            .body(requestBody)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .statusCode(anyOf(is(201), is(409))); // 可能已存在

        // 第二次创建相同用户名
        requestBody = """
            {
                "username": "duplicate_api_user",
                "email": "second@example.com",
                "password": "Password123!"
            }
            """;

        given()
            .body(requestBody)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .statusCode(409)
            .body("errorCode", equalTo("DUPLICATE_USERNAME"));
    }

    // ==================== DELETE /api/users/{id} ====================

    @Test
    @DisplayName("DELETE /api/users/{id} - 成功删除返回 204")
    void delete_ExistingId_Returns204() {
        // 先创建一个用户
        Long userId = given()
            .body("""
                {
                    "username": "delete_api_user",
                    "email": "delete@example.com",
                    "password": "Password123!"
                }
                """)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .extract()
            .path("id");

        // 删除
        given()
            .pathParam("id", userId)
        .when()
            .delete("/users/{id}")
        .then()
            .statusCode(204);
    }

    @Test
    @DisplayName("DELETE /api/users/{id} - 删除后再次查询返回 404")
    void delete_AfterDeletion_Returns404WhenQuery() {
        // 先创建一个用户
        Long userId = given()
            .body("""
                {
                    "username": "delete_verify_user",
                    "email": "delete_verify@example.com",
                    "password": "Password123!"
                }
                """)
            .contentType(ContentType.JSON)
        .when()
            .post("/users")
        .then()
            .extract()
            .path("id");

        // 删除
        given()
            .pathParam("id", userId)
        .when()
            .delete("/users/{id}")
        .then()
            .statusCode(204);

        // 验证已删除
        given()
            .pathParam("id", userId)
        .when()
            .get("/users/{id}")
        .then()
            .statusCode(404);
    }
}
