package com.focus.server;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.focus.server.mapper")
public class FocusServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(FocusServerApplication.class, args);
    }
}

