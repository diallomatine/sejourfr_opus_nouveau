package com.sejourfr.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.retry.annotation.EnableRetry;

@SpringBootApplication
@ConfigurationPropertiesScan(basePackages = {
    "com.sejourfr.app.config",
    "com.sejourfr.app.audioquestion.config"
})
@EnableRetry
public class SejourFrAppApplication {

    public static void main(String[] args) {
        SpringApplication.run(SejourFrAppApplication.class, args);
    }
}
