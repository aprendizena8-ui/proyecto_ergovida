package com.ergovida.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "ergovida.recordatorios.scheduler.enabled=false")
class BackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
