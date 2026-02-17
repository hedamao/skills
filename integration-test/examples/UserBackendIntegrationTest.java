package com.example.integration.backend;

import com.example.entity.UserEntity;
import com.example.repository.UserRepository;
import com.example.service.UserService;
import com.example.service.dto.UserCreateRequest;
import com.example.service.dto.UserDTO;
import com.example.service.exception.UserNotFoundException;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;

/**
 * User 后端集成测试示例
 *
 * 演示如何使用 Testcontainers 进行后端集成测试
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@DisplayName("User 模块后端集成测试")
class UserBackendIntegrationTest {

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

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("创建用户：数据正确落库")
    void createUser_ValidData_PersistsToDatabase() {
        // Arrange
        UserCreateRequest request = new UserCreateRequest();
        request.setUsername("testuser");
        request.setEmail("test@example.com");
        request.setPassword("SecurePass123!");

        // Act
        UserDTO result = userService.createUser(request);

        // Assert - 验证 Service 返回
        assertThat(result.getId()).isNotNull();
        assertThat(result.getUsername()).isEqualTo("testuser");
        assertThat(result.getEmail()).isEqualTo("test@example.com");

        // Assert - 验证数据库
        Optional<UserEntity> persisted = userRepository.findById(result.getId());
        assertThat(persisted).isPresent();
        assertThat(persisted.get().getUsername()).isEqualTo("testuser");
    }

    @Test
    @DisplayName("查询用户：根据 ID 查询存在的数据")
    void findById_DataExists_ReturnsUser() {
        // Arrange - 先创建一条数据
        UserEntity entity = new UserEntity();
        entity.setUsername("existinguser");
        entity.setEmail("existing@example.com");
        entity.setPassword("hashed_password");
        UserEntity saved = userRepository.save(entity);

        // Act
        UserDTO result = userService.findById(saved.getId());

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(saved.getId());
        assertThat(result.getUsername()).isEqualTo("existinguser");
    }

    @Test
    @DisplayName("查询用户：查询不存在的数据抛出异常")
    void findById_DataNotFound_ThrowsUserNotFoundException() {
        // Arrange
        Long nonExistentId = 99999L;

        // Act & Assert
        assertThatThrownBy(() -> userService.findById(nonExistentId))
            .isInstanceOf(UserNotFoundException.class)
            .hasMessageContaining("User not found");
    }

    @Test
    @DisplayName("事务回滚：业务异常时数据不会被持久化")
    void createUser_DuplicateUsername_RollbacksTransaction() {
        // Arrange - 先创建一个用户
        UserEntity existing = new UserEntity();
        existing.setUsername("duplicate_user");
        existing.setEmail("first@example.com");
        existing.setPassword("password");
        userRepository.save(existing);

        long countBefore = userRepository.count();

        // Act & Assert - 尝试创建相同用户名的用户
        UserCreateRequest request = new UserCreateRequest();
        request.setUsername("duplicate_user");
        request.setEmail("second@example.com");
        request.setPassword("password");

        assertThatThrownBy(() -> userService.createUser(request))
            .isInstanceOf(RuntimeException.class); // 假设抛出业务异常

        // Assert - 验证事务回滚
        long countAfter = userRepository.count();
        assertThat(countAfter).isEqualTo(countBefore);
    }

    @Test
    @DisplayName("更新用户：数据正确更新到数据库")
    void updateUser_ValidData_UpdatesDatabase() {
        // Arrange - 先创建一条数据
        UserEntity entity = new UserEntity();
        entity.setUsername("updateuser");
        entity.setEmail("original@example.com");
        entity.setPassword("password");
        UserEntity saved = userRepository.save(entity);

        // Act
        UserDTO result = userService.updateEmail(saved.getId(), "updated@example.com");

        // Assert
        assertThat(result.getEmail()).isEqualTo("updated@example.com");

        // 验证数据库
        UserEntity updated = userRepository.findById(saved.getId()).orElseThrow();
        assertThat(updated.getEmail()).isEqualTo("updated@example.com");
    }

    @Test
    @DisplayName("删除用户：数据从数据库中删除")
    void deleteUser_ExistingId_RemovesFromDatabase() {
        // Arrange - 先创建一条数据
        UserEntity entity = new UserEntity();
        entity.setUsername("deleteuser");
        entity.setEmail("delete@example.com");
        entity.setPassword("password");
        UserEntity saved = userRepository.save(entity);

        // Act
        userService.deleteUser(saved.getId());

        // Assert
        Optional<UserEntity> deleted = userRepository.findById(saved.getId());
        assertThat(deleted).isEmpty();
    }
}
