package com.sejourfr.app;

import com.sejourfr.app.config.DotenvLoader;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.retry.annotation.EnableRetry;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@ConfigurationPropertiesScan(basePackages = {
        "com.sejourfr.app.config",
        "com.sejourfr.app.audioquestion.config"
})
@EnableRetry
@EnableAsync
@EnableScheduling
public class SejourFrAppApplication {

    public static void main(String[] args) {
        DotenvLoader.loadIfPresent();
        SpringApplication.run(SejourFrAppApplication.class, args);
    }
}
