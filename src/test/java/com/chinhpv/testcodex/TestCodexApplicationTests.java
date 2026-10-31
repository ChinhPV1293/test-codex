package com.chinhpv.testcodex;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import javax.sql.DataSource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class TestCodexApplicationTests {
    @Autowired
    private DataSource dataSource;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void databaseConnectionWorks() throws Exception {
        try (var connection = dataSource.getConnection();
             var statement = connection.createStatement();
             var result = statement.executeQuery("SELECT 1")) {
            assertThat(result.next()).isTrue();
            assertThat(result.getInt(1)).isEqualTo(1);
        }
    }

    @Test
    void webServerResponds() {
        assertThat(restTemplate.getForEntity("/", String.class).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }
}
