package com.sejourfr.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan(basePackages = "com.sejourfr.app.config")
public class SejourFrAppApplication {

    public static void main(String[] args) {
        SpringApplication.run(SejourFrAppApplication.class, args);
    }
}
